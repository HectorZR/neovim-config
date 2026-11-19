local PILL_LEFT, PILL_RIGHT = "\u{e0b6}", "\u{e0b4}"

return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.options.component_separators = ""
    opts.options.section_separators = { left = PILL_RIGHT, right = PILL_LEFT }

    opts.sections.lualine_a = {
      { "mode", separator = { left = PILL_LEFT, right = PILL_RIGHT }, padding = { left = 0, right = 1 } },
    }
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
      { "location", separator = { left = PILL_LEFT, right = PILL_RIGHT }, padding = { left = 1, right = 0 } },
    }
  end,
}
