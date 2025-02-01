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
    "echasnovski/mini.move",
    event = "VeryLazy",
    opts = {},
  },
  { "mg979/vim-visual-multi" },
}
