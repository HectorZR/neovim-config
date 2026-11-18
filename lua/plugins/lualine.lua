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
  end,
}
