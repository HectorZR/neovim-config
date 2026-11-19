return {
  "folke/noice.nvim",
  opts = {
    presets = {
      lsp_doc_border = true,
    },
    cmdline = {
      format = {
        -- Remove treesitter highlighting (ft) for substitute to avoid
        -- "Query error" popups when the regex parser is not installed
        substitute = { pattern = "^:%%?s", icon = " ", ft = nil },
      },
    },
  },
}
