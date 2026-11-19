-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

if vim.fn.has("nvim-0.12") == 0 then
  vim.notify("This config targets Neovim 0.12+", vim.log.levels.WARN)
end

vim.g.lazyvim_picker = "snacks"

vim.opt.wrap = true
vim.o.winborder = "rounded"
vim.o.statuscolumn = "%!v:lua.require'user.statuscolumn'.get()"

-- keep the statusline short: no pending keys, no code location
vim.o.showcmd = false
vim.g.trouble_lualine = false

-- remember the picked colorscheme and keep the chosen light or dark mode (see user.colorscheme)
require("user.colorscheme").setup()

-- soft diff colors that follow the active colorscheme (see user.theme)
require("user.theme").setup()

-- only the active window shows line numbers and the current line (see user.focus)
require("user.focus").setup()

-- one tab per git worktree, labelled with its branch (see user.worktrees)
require("user.worktrees").setup()
