-- Options are automatically loaded before lazy.nvim startup.
require("config.remote_clipboard").setup()

vim.opt.relativenumber = false
vim.g.autoformat = false
vim.g.lazyvim_ts_lsp = "tsgo"
vim.g.lazyvim_python_lsp = "ty"
