-- Git worktrees panel (snacks.picker): one tab per worktree. See lua/user/worktrees.lua
return {
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
  },
}
