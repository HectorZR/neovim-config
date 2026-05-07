return {
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
