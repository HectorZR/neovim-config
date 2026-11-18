return {
  "folke/noice.nvim",
  opts = {
    cmdline = {
      format = {
        -- Remove treesitter highlighting (ft) for substitute to avoid
        -- "Query error" popups when the regex parser is not installed
        substitute = { pattern = "^:%%?s", icon = " ", ft = nil },
      },
    },
  },
}
