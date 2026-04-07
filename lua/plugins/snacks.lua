return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.picker = opts.picker or {}
    opts.picker.sources = opts.picker.sources or {}
    opts.picker.sources.explorer = vim.tbl_deep_extend("force", opts.picker.sources.explorer or {}, {
      layout = { preset = "sidebar", layout = { position = "right" } },
    })

    opts.dashboard = opts.dashboard or {}
    opts.dashboard.enabled = true
    opts.dashboard.preset = opts.dashboard.preset or {}
    opts.dashboard.preset.header = [[
  ██╗   ██╗███████╗
  ██║   ██║╚══███╔╝
████████║  ███╔╝
██╔═══██║ ███╔╝
  ██║   ██║███████╗
  ╚═╝   ╚═╝╚══════╝
]]
  end,
}
