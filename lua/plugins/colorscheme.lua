return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    -- floats share the editor background, so their rounded border is all that frames them
    opts = {
      float = { transparent = true, solid = false },
      custom_highlights = function(colors)
        return {
          Pmenu = { bg = colors.base, fg = colors.overlay2 },
          BlinkCmpMenuBorder = { bg = colors.base, fg = colors.blue },
        }
      end,
    },
  },
  { "ellisonleao/gruvbox.nvim", opts = { contrast = "soft" } },
  {
    "rebelot/kanagawa.nvim",
    opts = {
      theme = "wave",
      background = { dark = "wave", light = "lotus" },
    },
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    opts = {
      variant = "auto",
      dark_variant = "main",
    },
  },
  {
    "neanias/everforest-nvim",
    version = false,
    lazy = false,
    priority = 1000,
    config = function()
      require("everforest").setup({
        background = "medium",
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-frappe",
    },
  },
}
