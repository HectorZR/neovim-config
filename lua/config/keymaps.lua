-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local set_keymap = vim.api.nvim_set_keymap

set_keymap("n", "<leader>o", "o<ESC>", { silent = true, desc = "Add empty line bellow cursor" })
set_keymap("n", "<leader>O", "O<ESC>", { silent = true, desc = "Add empty line above cursor" })
set_keymap("i", "<S-CR>", "<ESC>o", { silent = true, desc = "Add empty line bellow cursor" })
set_keymap("i", "<C-CR>", "<ESC>O", { silent = true, desc = "Add empty line above cursor" })

set_keymap("n", "<leader>ce", "^ggVG", { silent = true, desc = "Select all content in file" })
