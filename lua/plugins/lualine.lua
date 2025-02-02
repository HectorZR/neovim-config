return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections.lualine_y = {}
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

    opts.tabline = {}
    opts.tabline.lualine_b = {
      { "buffers", mode = 2, use_mode_colors = true },
    }
  end,
}
