return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections.lualine_y = {
      {
        function()
          return require("user.worktrees").pr_status()
        end,
        color = function()
          return require("user.worktrees").pr_status_color()
        end,
      },
    }
    opts.sections.lualine_z = {
      {
        "progress",
        separator = " ",
        padding = { left = 1, right = 0 },
      },
      {
        "location",
        padding = { left = 0, right = 1 },
      },
    }
  end,
}
