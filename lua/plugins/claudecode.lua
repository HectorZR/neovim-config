return {
  "coder/claudecode.nvim",
  cond = function()
    return vim.fn.executable("claude") == 1
  end,
  dependencies = { "folke/snacks.nvim" },
  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = { "v" }, desc = "Send to Claude Code" },
  },
  config = true,
}
