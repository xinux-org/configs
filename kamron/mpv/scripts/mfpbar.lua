--[[
	This file is part of mfpbar.
	
	mfpbar is free software: you can redistribute it and/or modify it
	under the terms of the GNU Affero General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.
	
	mfpbar is distributed in the hope that it will be useful, but WITHOUT
	ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
	FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License
	for more details.
	
	You should have received a copy of the GNU Affero General Public License
	along with mfpbar. If not, see <https://www.gnu.org/licenses/>.
]]

local msg = require('mp.msg')
local utils = require('mp.utils')
local mpopt = require('mp.options')

-- poor man's enum

local pbar_uninit      = 0
local pbar_hidden      = 1
local pbar_minimized   = 2
local pbar_active      = 3

-- globals

local state = {
	osd = nil,
	dpy_w = 0,
	dpy_h = 0,
	pbar = pbar_uninit,
	mouse = nil,
	mouse_prev = nil,
	cached_ranges = nil,
	duration = nil,
	chapters = nil,
	timeout = nil,
	time_observed = false,
	press_bounded = false,
	fullscreen = false,
	thumbfast = {
		width = 0,
		height = 0,
		disabled = true,
		available = false
	},
}

local opt = {
	pbar_height = 2,
	pbar_minimized_height = 0.5,
	pbar_color = "CCCCCC",
	pbar_bg_alpha = "3F",
	pbar_fullscreen_hide = true,
	cachebar_height = 0.24,
	cachebar_color = "1C6C89",
	cachebar_uncached_color = "CC3A2A",
	cachebar_uncached_alpha = "70",
	-- TODO: allow selecting "duration" as well ?
	timeline_rhs = "time-remaining",
	hover_bar_color = "BDAE93",
	font_size = 16,
	font_pad = 4, -- TODO: rename this to hpad ?
	-- TODO: add a configurable vpad as well ?
	font_border_width = 2,
	font_border_color = "000000",
	proximity = 40,
	preview_border_width = 2,
	preview_border_color = "BDAE93",
	chapter_marker_size = 3,
	chapter_marker_color = "BDAE93",
	chapter_marker_border_width = 1,
	chapter_marker_border_color = "161616",
	minimize_timeout = 3,

	debug = false,
}

local zassert = function() end

-- function implementation

-- ASS uses BBGGRR format, which fucking sucks
local function rgb_to_ass(color)
	if (not string.len(color) == 6) then
		msg.error("Invalid color: " .. color)
		return "FFFFFF"
	end
	local r = string.sub(color, 1, 2)
	local g = string.sub(color, 3, 4)
	local b = string.sub(color, 5, 6)
	return string.upper(b .. g .. r)
end

local function grab_chapter_name_at(sec)
	zassert(state.chapters)
	local name = nil
	local psec = -1
	for _, c in ipairs(state.chapters) do
		if (sec > c.time) then
			name = c.title
		end
		zassert(psec <= c.time)
		psec = c.time
	end
	return name
end

local function format_time(t)
	local h = math.floor(t / (60 * 60))
	t = t - (h * 60 * 60)
	local m = math.floor(t / 60)
	local s = t - (m * 60)
	return string.format("%.2d:%.2d:%.2d", h, m, s)
end

local function round(n)
	zassert(n >= 0)
	return math.floor(n + 0.5)
end

local function clamp(n, min, max)
	return math.min(math.max(n, min), max)
end

local function hover_to_sec(mx, dw, duration)
	zassert(duration)
	local n = duration * ((mx + 0.5) / dw)
	return clamp(n, 0, duration)
end

local function render()
	state.osd:update()
	state.osd.data = nil
end

local function draw_append(text)
	if (state.osd.data == nil) then
		state.osd.data = text
	else
		state.osd.data = state.osd.data .. '\n' .. text
	end
end

local function draw_rect_point(x0, y0, x1, y1, x2, y2, x3, y3, color, opt)
	local s = '{\\pos(0, 0)}'
	opt = opt or {}
	s = s .. '{\\1c&' .. color .. '&}'
	s = s .. '{\\1a&' .. (opt.alpha or "00") .. '&}'
	s = s .. '{\\bord' .. (opt.bw or '0') .. '}'
	s = s .. '{\\3c&' .. (opt.bcolor or "000000") .. '&}'
	s = s .. string.format(
		'{\\p1}m %d %d l %d %d %d %d %d %d{\\p0}',
		x0, y0, x1, y1, x2, y2, x3, y3
	)
	draw_append(s)
end

local function draw_rect(x, y, w, h, color, opt)
	draw_rect_point(
		x,      y,
		x + w,  y,
		x + w,  y + h,
		x,      y + h,
		color, opt
	)
end

local function draw_text(x, y, size, text, opt)
	local s = string.format('{\\pos(%d, %d)}{\\fs%d}', x, y, size)
	opt = opt or {}
	s = s .. '{\\bord' .. (opt.bw or '0') .. '}'
	s = s .. '{\\3c&' .. (opt.bcolor or "000000") .. '&}'
	s = s .. text
	draw_append(s)
end

-- TODO: make this less janky.
local function pbar_draw()
	local dpy_w = state.dpy_w
	local dpy_h = state.dpy_h
	local ypos = 0
	local play_pos = mp.get_property_native("percent-pos")
	local duration = state.duration
	local clist = state.chapters

	zassert(state.pbar == pbar_minimized or state.pbar == pbar_active)

	if (play_pos == nil or dpy_w == 0 or dpy_h == 0) then
		return
	end

	-- L0: playback cursor
	local pb_h = state.pbar == pbar_minimized and opt.pbar_minimized_height or opt.pbar_height
	zassert(pb_h > 0)
	pb_h = dpy_h * (pb_h / 100)
	pb_h = math.max(round(pb_h), 4)
	local pb_w = dpy_w * (play_pos/100.0)
	local pb_y = dpy_h - (pb_h + ypos)
	draw_rect(0,    pb_y, pb_w, pb_h, opt.pbar_color)
	draw_rect(pb_w, pb_y, dpy_w - pb_w, pb_h, "000000", { alpha = opt.pbar_bg_alpha })
	ypos = ypos + pb_h

	if (duration) then
		-- L1: cache cusor
		if (state.cached_ranges and opt.cachebar_height > 0) then
			zassert(#state.cached_ranges > 0)
			local ch = dpy_h * (opt.cachebar_height / 100)
			ch = math.max(round(ch), 2)
			draw_rect(
				0, dpy_h - (ch + ypos), dpy_w, ch,
				opt.cachebar_uncached_color,
				{ alpha = opt.cachebar_uncached_alpha }
			)
			for _, range in ipairs(state.cached_ranges) do
				local s = range['start']
				local e = range['end']
				local sp = dpy_w * (s / duration)
				local ep = (dpy_w * (e / duration)) - sp

				draw_rect(sp, dpy_h - (ch + ypos), ep, ch, opt.cachebar_color)
			end
			ypos = ypos + ch
		end

		-- L0-???: chapters
		if (clist and opt.chapter_marker_size > 0) then
			zassert(#clist > 0)
			local bw = opt.chapter_marker_border_width
			local tw = opt.chapter_marker_size
			local miny = tw + bw + 1 -- +1 for pad
			local y = dpy_h - math.max(pb_h / 2, miny)
			for _, c in ipairs(clist) do
				local x = dpy_w * (c.time / duration)
				draw_rect_point(
					x - tw,  y,
					x,       y - tw,
					x + tw,  y,
					x,       y + tw,
					opt.chapter_marker_color,
					{ bw = bw, bcolor = opt.chapter_marker_border_color }
				)
			end
			ypos = math.max(ypos, dpy_h - (y + tw + bw))
		end
	end

	if (state.pbar == pbar_active) then
		local fs = opt.font_size
		local pad = opt.font_pad
		local fopt = { bw = opt.font_border_width, bcolor = opt.font_border_color }

		-- L2: timeline
		-- LHS: current playback position
		local time = mp.get_property_osd("time-pos", "00:00:00")
		draw_text(pad, dpy_h - (ypos + fs), fs, time, fopt)
		-- RHS: time/playback remaining
		local rem = "-" .. mp.get_property_osd(opt.timeline_rhs, "99:99:99")
		draw_text(dpy_w - pad, dpy_h - (ypos + fs), fs, "{\\an9}" .. rem, fopt)
		ypos = ypos + fs + (fopt.bw * 2)

		if (duration) then
			zassert(state.mouse)

			-- L0-2: hovered timeline
			local hover_sec = hover_to_sec(state.mouse.x, dpy_w, duration)
			local hover_text = format_time(hover_sec)
			draw_rect(
				math.max(state.mouse.x - 1, 0), dpy_h - ypos,
				2, ypos, opt.hover_bar_color
			)
			local fw = fs * 2 -- guesstimate ¯\_(ツ)_/¯
			local x = clamp(state.mouse.x, pad + fw, dpy_w - (pad + fw))
			draw_text(
				x, dpy_h - (ypos + fs), fs,
				"{\\an8}" .. hover_text, fopt
			)
			ypos = ypos + fs + (fopt.bw * 2)

			-- L3: chapter name
			local cname = clist and grab_chapter_name_at(hover_sec) or nil
			if cname then
				zassert(cname)
				local fw = string.len(cname) * fs * 0.28 -- guesstimate again
				local x = clamp(state.mouse.x, pad + fw, dpy_w - (pad + fw))
				draw_text(
					x, dpy_h - (ypos + fs),
					fs, "{\\an8}" .. cname, fopt
				)
				ypos = ypos + fs + (fopt.bw * 2)
			end

			-- L4: preview thumbnail
			if not state.thumbfast.disabled then
				local pw = opt.preview_border_width
				local hpad = 4 + pw
				local tw = state.thumbfast.width
				local th = state.thumbfast.height
				local y = dpy_h - (ypos + th + pw)
				local x = state.mouse.x - (tw / 2)
				x = clamp(x, hpad, dpy_w - (hpad + tw))
				mp.commandv(
					"script-message-to", "thumbfast", "thumb",
					hover_sec, x, y
				)
				ypos = ypos + th + pw

				-- L4: preview border
				if pw > 0 then
					local c = opt.preview_border_color
					draw_rect(
						x, y, tw, th, "161616",
						{ alpha = "7F", bw = pw, bcolor = c }
					)
					ypos = ypos + pw
				end
			end
		end
	end

	render()
end

local function pbar_pressed()
	zassert(state.mouse.hover)
	zassert(state.pbar == pbar_active)
	if (state.duration) then
		mp.set_property("time-pos",  hover_to_sec(
			state.mouse.x, state.dpy_w, state.duration
		));
	end
end

local function pbar_update(next_state)
	local dpy_w = state.dpy_w
	local dpy_h = state.dpy_h

	if (dpy_w == 0 or dpy_h == 0 or
	    state.pbar == next_state or state.pbar == pbar_uninit)
	then
		return
	end

	zassert(dpy_w > 0)
	zassert(dpy_h > 0)

	local statestr = {
		[pbar_uninit] = "uninit", [pbar_active] = "active",
		[pbar_minimized] = "minimized", [pbar_hidden] = "hidden"
	}
	msg.debug('[UPDATE]: ', statestr[state.pbar], '=> ', statestr[next_state]);

	-- TODO: reduce latency when pbar is active
	if (next_state == pbar_active) then
		state.pbar = pbar_active
		pbar_draw()
		if (not state.press_bounded) then
			mp.add_forced_key_binding('mbtn_left', 'pbar_pressed', pbar_pressed)
			state.press_bounded = true
		end
		if (not state.time_observed) then
			mp.observe_property("time-pos", nil, pbar_draw)
			state.time_observed = true
		end
	else
		if (next_state == pbar_minimized) then
			zassert(opt.pbar_minimized_height > 0)
			state.pbar = pbar_minimized
			pbar_draw()
			if (not state.time_observed) then
				mp.observe_property("time-pos", nil, pbar_draw)
				state.time_observed = true
			end
		elseif (next_state == pbar_hidden) then
			zassert(state.pbar ~= pbar_hidden)
			state.pbar = pbar_hidden
			state.osd.data = '' -- clear everything
			render()
			zassert(state.time_observed)
			mp.unobserve_property(pbar_draw)
			state.time_observed = false
		else
			zassert(false, "unreachable")
		end

		if (state.press_bounded) then
			mp.remove_key_binding('pbar_pressed')
			state.press_bounded = false
		end
		state.mouse = nil
		if (state.thumbfast.available) then
			mp.commandv("script-message-to", "thumbfast", "clear")
		end
	end
end

local function pbar_minimize_or_hide()
	msg.debug("[MIN-HIDE]")
	if (opt.pbar_minimized_height > 0 and not (opt.pbar_fullscreen_hide and state.fullscreen)) then
		pbar_update(pbar_minimized)
	else
		pbar_update(pbar_hidden)
	end
end

local function mouse_isactive(m)
	return m.hover and math.abs(m.y - state.dpy_h) < opt.proximity
end

local function update_mouse_pos(kind, mouse)
	zassert(kind == "mouse-pos")
	state.mouse_prev = state.mouse or { hover = false }
	state.mouse = mouse
	msg.debug('[MOUSE] hover = ', mouse.hover, ' x = ', mouse.x, ' y = ', mouse.y)

	local dpy_w = state.dpy_w
	local dpy_h = state.dpy_h

	if (dpy_w == 0 or dpy_h == 0) then
		return
	end

	zassert(dpy_w > 0)
	zassert(dpy_h > 0)
	zassert(mouse)

	-- TODO: ensure there's enough height to draw our stuff ?
	if (mouse_isactive(state.mouse_prev) and mouse_isactive(mouse)) then
		-- TODO: a better way to do this without killing/resuming a
		-- timer on each mouse update?
		state.timeout:kill()
		state.timeout:resume()
		pbar_update(pbar_active)
	else
		state.timeout:kill()
		pbar_minimize_or_hide()
	end
end

local function update_fullscreen(kind, fs)
	zassert(kind == "fullscreen")
	state.fullscreen = fs
	msg.debug('[FULLSCREEN] fs = ', fs)
	pbar_minimize_or_hide()
end

local function update_focus(kind, foc)
	zassert(kind == "focused")
	msg.debug('[FOCUS] focus = ', foc)
	state.mouse_prev = { hover = false, x = 0, y = 0 }
end

local function set_dpy_size(kind, osd)
	zassert(kind == "osd-dimensions")
	state.dpy_w     = osd.w
	state.osd.res_x = osd.w
	state.dpy_h     = osd.h
	state.osd.res_y = osd.h
	msg.debug('[DPY] w = ', osd.w, ' h = ', osd.h)

	-- HACK: ensure we don't obstruct the console (excluding the preview and hovered timeline)
	-- the shared_script_property_* functions are documented as undocumented :)
	-- and users are discouraged to use them, but whatever...
	local b = (opt.font_size + (opt.font_border_width * 2) + 8) / state.dpy_h -- +8 padding
	b = b + ((opt.pbar_minimized_height + opt.cachebar_height) / 100.0)
	utils.shared_script_property_set(
		'osc-margins',
		string.format('%f,%f,%f,%f', 0, 0, 0, b)
	)
end

local function set_cache_state(kind, c)
	zassert(kind == "demuxer-cache-state")
	if (c == nil) then
		state.cached_ranges = nil
	else
		local r = c['seekable-ranges']
		if #r > 0 then
			state.cached_ranges = r
		else
			state.cached_ranges = nil
		end
	end
end

local function set_duration(kind, d)
	zassert(kind == "duration")
	state.duration = d
end

local function set_chapter_list(kind, c)
	zassert(kind == "chapter-list")
	if (c and #c > 0) then
		state.chapters = c
		table.sort(state.chapters, function(a, b) return a.time < b.time end)
	else
		state.chapters = nil
	end
end

local function set_thumbfast(json)
	local data = utils.parse_json(json)
	if (type(data) ~= "table" or not data.width or not data.height) then
		msg.error("thumbfast-info: received json didn't produce a table with thumbnail information")
	else
		state.thumbfast = data
	end
end

local function pbar_init(kind, thing)
	zassert(kind == 'vo-configured')
	msg.debug("[VO-CONFIGURED]", thing, state.pbar)

	if thing then
		zassert(state.pbar == pbar_uninit)
		state.pbar = pbar_hidden
		if (opt.pbar_minimized_height > 0) then
			pbar_update(pbar_minimized)
		end
		mp.unobserve_property(pbar_init)
	end
end

local function init()
	mpopt.read_options(opt, "mfpbar")
	for k,v in pairs(opt) do
		if string.find(k, "_color$") then
			opt[k] = rgb_to_ass(v)
		end
	end

	if opt.debug then
		msg.debug("[ASSERTIONS] enabled")
		zassert = assert
	else
		zassert(false)
	end

	state.osd = mp.create_osd_overlay("ass-events")
	mp.observe_property("osd-dimensions", "native", set_dpy_size)
	mp.observe_property('demuxer-cache-state', 'native', set_cache_state)
	mp.observe_property('duration', 'native', set_duration)
	mp.observe_property('chapter-list', 'native', set_chapter_list)
	mp.register_script_message("thumbfast-info", set_thumbfast)
	mp.observe_property('fullscreen', 'native', update_fullscreen)
	mp.observe_property('focused', 'native', update_focus)

	-- NOTE: mouse-pos doesn't work mpv versions older than v33
	mp.observe_property("mouse-pos", "native", update_mouse_pos)

	if (opt.minimize_timeout > 0) then
		state.timeout = mp.add_timeout(opt.minimize_timeout, pbar_minimize_or_hide)
		state.timeout:kill() -- update_mouse_pos() will kill/resume this as needed
	else
		state.timeout = { kill = function() end, resume = function() end }
	end

	-- HACK: mpv doesn't open the window instantly by default.
	-- so wait for 'vo-configured' as a hook for when the window opens.
	mp.observe_property('vo-configured', 'native', pbar_init)
end

init()
