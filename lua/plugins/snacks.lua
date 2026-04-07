return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.picker = opts.picker or {}
    opts.picker.sources = opts.picker.sources or {}
    opts.picker.sources.explorer = vim.tbl_deep_extend("force", opts.picker.sources.explorer or {}, {
      layout = { preset = "sidebar", preview = "main", layout = { position = "right" } },
    })

    opts.image = opts.image or {}
    opts.image.enabled = true

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
