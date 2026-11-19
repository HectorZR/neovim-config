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
      -- the last one you picked with <leader>uC, catppuccin-frappe the first time (see user.colorscheme)
      colorscheme = function()
        require("user.colorscheme").load()
      end,
    },
  },
}
