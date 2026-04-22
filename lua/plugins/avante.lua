return {
  "yetone/avante.nvim",
  cond = function()
    return vim.fn.executable("opencode") == 1
      or vim.fn.executable("claude") == 1
      or vim.uv.fs_stat(vim.fn.expand("~/.config/github-copilot")) ~= nil
  end,
  opts = {
    provider = "copilot",
    providers = {
      copilot = {
        model = "claude-sonnet-4.6",
      },
    },
  },
}
