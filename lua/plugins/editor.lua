return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
      },
    },
  },
  {
    "nvim-mini/mini.move",
    event = "VeryLazy",
    opts = {},
  },
  { "mg979/vim-visual-multi" },
}
