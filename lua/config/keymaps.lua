-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

map("n", "<leader>o", "o<Esc>", { desc = "Add empty line below cursor" })
map("n", "<leader>O", "O<Esc>", { desc = "Add empty line above cursor" })
map("i", "<S-CR>", "<Esc>o", { desc = "Add empty line below cursor" })
map("i", "<C-CR>", "<Esc>O", { desc = "Add empty line above cursor" })

map("n", "<leader>ce", "ggVG", { desc = "Select all content in file" })
