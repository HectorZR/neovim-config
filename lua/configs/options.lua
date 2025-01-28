local api = vim.api
local g = vim.g
local opt = vim.opt

-- Remap leader and local leader to <Space>
api.nvim_set_keymap("", "<Space>", "<Nop>", { noremap = true, silent = true })
g.mapleader = " "
g.maplocalleader = " "

opt.termguicolors = true      -- Enable colors in terminal
opt.hlsearch = true           --Set highlight on search
opt.number = true             --Make line numbers default
opt.relativenumber = true     --Make relative number default
opt.mouse = "a"               --Enable mouse mode
opt.breakindent = true        --Enable break indent
opt.undofile = true           --Save undo history
opt.ignorecase = true         --Case insensitive searching unless /C or capital in search
opt.smartcase = true          -- Smart case
opt.updatetime = 500          --Decrease update time
opt.timeoutlen = 500          --Time to wait for a mapped sequence to complete (in milliseconds)
opt.signcolumn = "yes"        -- Always show sign column
opt.clipboard = "unnamedplus" -- Access system clipboard
opt.showtabline = 2           -- Always show tabs
opt.title = true              -- Set title of window to the value of the titlestring
opt.titlestring = '%F'        -- Set title of window to the current file name

vim.bo.expandtab = true       -- Use spaces instead of tabs
vim.bo.shiftwidth = 2
vim.bo.tabstop = 2
vim.bo.softtabstop = 2
vim.bo.textwidth = 120

-- Highlight on yank
vim.cmd [[
  augroup YankHighlight
    autocmd!
    autocmd TextYankPost * silent! lua vim.highlight.on_yank()
  augroup end
]]
