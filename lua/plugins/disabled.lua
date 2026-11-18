-- Plugins from LazyVim that Neovim 0.12 already covers natively.
-- See README "Native replacements" for what replaces each one.
return {
  -- ui2 (enabled in config/options.lua) replaces the cmdline/messages UI
  { "folke/noice.nvim", enabled = false },
  -- user.statusline replaces it, built on the native statusline helpers
  { "nvim-lualine/lualine.nvim", enabled = false },
  -- native `gc` / `gcc` already resolve 'commentstring' through treesitter injections
  { "folke/ts-comments.nvim", enabled = false },
  -- tabs are used for worktrees (see user.worktrees), not buffers
  { "akinsho/bufferline.nvim", enabled = false },
  -- snacks.picker is the only picker
  { "ibhagwan/fzf-lua", enabled = false },
}
