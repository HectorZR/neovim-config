return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.picker = opts.picker or {}
    opts.picker.sources = opts.picker.sources or {}
    opts.picker.sources.explorer = vim.tbl_deep_extend("force", opts.picker.sources.explorer or {}, {
      layout = { preset = "sidebar", preview = "main", layout = { position = "right" } },
      -- Start with preview hidden; toggle with <M-p> or P will show it in the main area
      on_show = function(picker)
        picker:toggle("preview", { enable = false })
      end,
    })
    opts.picker.sources.projects = vim.tbl_deep_extend("force", opts.picker.sources.projects or {}, {
      dev = { "~/dev", "~/projects", "~/Developer" },
    })

    local function is_wsl()
      local f = io.open("/proc/version", "r")
      if f then
        local content = f:read("*a")
        f:close()
        return content:lower():find("microsoft") ~= nil
      end
      return false
    end
    opts.image = opts.image or {}
    opts.image.enabled = not is_wsl()

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
