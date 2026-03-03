return {
  "NickvanDyke/opencode.nvim",
  enabled = vim.fn.has("win32") == 0,
  dependencies = {
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  keys = {
    {
      "<leader>ia",
      function()
        require("opencode").toggle()
      end,
      mode = { "n" },
      desc = "Toggle OpenCode",
    },
    {
      "<leader>is",
      function()
        require("opencode").select({ submit = true })
      end,
      mode = { "n", "x" },
      desc = "OpenCode select",
    },
    {
      "<leader>ii",
      function()
        require("opencode").ask("")
      end,
      mode = { "n", "x" },
      desc = "OpenCode ask",
    },
    {
      "<leader>iI",
      function()
        require("opencode").ask("@this: ", { submit = true })
      end,
      mode = { "n", "x" },
      desc = "OpenCode ask with context",
    },
    {
      "<leader>ib",
      function()
        require("opencode").ask("@file ", { submit = true })
      end,
      mode = { "n", "x" },
      desc = "OpenCode ask about buffer",
    },
    {
      "<leader>ip",
      function()
        require("opencode").prompt("@this", { submit = true })
      end,
      mode = { "n", "x" },
      desc = "OpenCode prompt",
    },
    -- Built-in prompts
    {
      "<leader>ipe",
      function()
        require("opencode").prompt("explain", { submit = true })
      end,
      mode = { "n", "x" },
      desc = "OpenCode explain",
    },
    {
      "<leader>ipf",
      function()
        require("opencode").prompt("fix", { submit = true })
      end,
      mode = { "n", "x" },
      desc = "OpenCode fix",
    },
    {
      "<leader>ipd",
      function()
        require("opencode").prompt("diagnose", { submit = true })
      end,
      mode = { "n", "x" },
      desc = "OpenCode diagnose",
    },
    {
      "<leader>ipr",
      function()
        require("opencode").prompt("review", { submit = true })
      end,
      mode = { "n", "x" },
      desc = "OpenCode review",
    },
    {
      "<leader>ipt",
      function()
        require("opencode").prompt("test", { submit = true })
      end,
      mode = { "n", "x" },
      desc = "OpenCode test",
    },
    {
      "<leader>ipo",
      function()
        require("opencode").prompt("optimize", { submit = true })
      end,
      mode = { "n", "x" },
      desc = "OpenCode optimize",
    },
  },
  config = function()
    vim.g.opencode_opts = {
      provider = {
        snacks = {
          win = {
            position = "right",
          },
        },
      },
      lsp = {
        enabled = true,
      },
    }
    vim.o.autoread = true
    require("opencode").setup()
  end,
}
