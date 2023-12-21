vim.cmd [[
  augroup Yank
  autocmd!
  autocmd TextYankPost * :call system('clip',@")
  augroup END
]]
