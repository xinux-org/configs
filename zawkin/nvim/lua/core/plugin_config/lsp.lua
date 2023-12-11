local lsp = require('lsp-zero').preset({})

lsp.on_attach(function(client, bufnr)
  -- see :help lsp-zero-keybindings
  -- to learn the available actions
  lsp.default_keymaps({ buffer = bufnr })
  local opts = { buffer = bufnr }
  vim.keymap.set({ 'n', 'x' }, 'fmt', function()
    vim.lsp.buf.format({ async = false, timeout_ms = 10000 })
  end, opts)
  lsp.buffer_autoformat()
end)

lsp.format_mapping('fmt', {
  format_opts = {
    async = false,
    timeout_ms = 10000,
  },
  servers = {
    ['prettier'] = { 'javascript', 'typescript', 'html', 'css' },
    ['rust_analyzer'] = { 'rust' },
    ['pyright'] = { 'python' },
    ['luals'] = { 'lua' }
  }
})

-- When you don't have mason.nvim installed
-- You'll need to list the servers installed in your system
lsp.setup_servers({ 'tsserver', 'eslint', 'html', 'cssls' })

-- (Optional) Configure lua language server for neovim
require('lspconfig').lua_ls.setup(lsp.nvim_lua_ls())

lsp.setup()
