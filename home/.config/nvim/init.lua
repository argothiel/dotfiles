-- bootstrap lazy.nvim, LazyVim and your plugins
require('config.lazy')

vim.cmd('colorscheme catppuccin')

vim.diagnostic.config({ update_in_insert = true })
