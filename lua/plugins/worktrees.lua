-- Git worktrees panel (snacks.picker): one tab per worktree. See lua/user/worktrees.lua
return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>gw",
        function()
          require("user.worktrees").pick()
        end,
        desc = "Worktrees (switch/new/remove)",
      },
      {
        "<leader>gW",
        function()
          require("user.worktrees").create()
        end,
        desc = "New worktree",
      },
      {
        "<leader>go",
        function()
          require("user.worktrees").open_pr()
        end,
        desc = "Open branch PR in browser",
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      opts.spec = opts.spec or {}
      table.insert(opts.spec, { "<leader>go", icon = { icon = "\u{f09b} ", color = "grey" } })
    end,
  },
}
