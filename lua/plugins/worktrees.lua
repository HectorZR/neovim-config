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
      local worktree = { icon = "\u{f126} ", color = "green" }
      vim.list_extend(opts.spec, {
        { "<leader>gw", icon = worktree },
        { "<leader>gW", icon = worktree },
        { "<leader>go", icon = { icon = "\u{f09b} ", color = "grey" } },
      })
    end,
  },
}
