return {
  "neovim/nvim-lspconfig",
  opts = {
    -- the margin sign marks every problem; the message shows on the cursor line
    diagnostics = { virtual_text = { current_line = true } },
  },
}
