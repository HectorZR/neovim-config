local has_go = vim.fn.executable("go") == 1

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = { enabled = has_go },
      },
    },
  },
}
