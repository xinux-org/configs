return require('packer').startup(function()
  use { 'wbthomason/packer.nvim' }
  --> Better Synax
  use { 'sheerun/vim-polyglot' }
  --> Auto Pairs
  use { 'jiangmiao/auto-pairs' }
  --> Startify
  use { 'mhinz/vim-startify' }
  --> Commentary
  use { 'tpope/vim-commentary' }
  --> Last Place
  use { 'farmergreg/vim-lastplace' }
  --> Intellisense
  use { 'neoclide/coc.nvim', branch = 'release' }
  --> File Explorer
  use { 'kyazdani42/nvim-tree.lua', requires = 'kyazdani42/nvim-web-devicons' }
  --> Theme (OneDark)
  use { 'navarasu/onedark.nvim' }
  --> Statusline
  use { 'nvim-lualine/lualine.nvim', requires = { 'kyazdani42/nvim-web-devicons', opt = true } }
  --> Bar
  use { 'romgrk/barbar.nvim', requires = {'kyazdani42/nvim-web-devicons'} }
  --> Notifier
  use { 'rcarriga/nvim-notify' }
  --> Signify (git)
  use { 'mhinz/vim-signify' }
end)
