-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

if vim.fn.has("nvim-0.12") == 0 then
  vim.notify("This config targets Neovim 0.12+", vim.log.levels.WARN)
end

vim.g.lazyvim_picker = "snacks"

vim.opt.wrap = true

-- soft diff colors that follow the active colorscheme (see user.theme)
require("user.theme").setup()

-- one tab per git worktree, labelled with its branch (see user.worktrees)
require("user.worktrees").setup()
