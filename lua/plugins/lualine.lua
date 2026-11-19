local PILL_LEFT, PILL_RIGHT = "\u{e0b6}", "\u{e0b4}"

return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.options.component_separators = ""
    opts.options.section_separators = { left = PILL_RIGHT, right = PILL_LEFT }
    -- side panels keep showing the file you were on
    opts.options.ignore_focus = { "codediff-explorer", "codediff-commits", "snacks_picker_list" }

    table.remove(opts.sections.lualine_c, 1) -- root directory
    local has_updates = require("lazy.status").has_updates
    opts.sections.lualine_x = vim.tbl_filter(function(component)
      return type(component) ~= "table" or component.cond ~= has_updates
    end, opts.sections.lualine_x)

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
