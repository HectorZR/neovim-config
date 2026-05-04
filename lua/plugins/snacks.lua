return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.picker = opts.picker or {}
    opts.picker.sources = opts.picker.sources or {}
    -- macOS: Option+H sends ˙ (U+02D9), Option+I sends ˆ (U+02C6) instead of ESC-prefixed
    -- sequences. Map these Unicode chars to the same toggle actions as <a-h> / <a-i>.
    -- On Windows/Linux, Alt+H/I send ESC+h/i correctly so <a-h>/<a-i> still handle those.
    local macos_picker_keys = {
      ["˙"] = { "toggle_hidden", mode = { "i", "n" } }, -- Option+H (macOS US layout)
      ["©"] = { "toggle_ignored", mode = { "i", "n" } }, -- Option+G (macOS US layout) — Option+I is a dead key on macOS
    }
    opts.picker.win = opts.picker.win or {}
    opts.picker.win.input = opts.picker.win.input or {}
    opts.picker.win.input.keys = vim.tbl_extend("force", opts.picker.win.input.keys or {}, macos_picker_keys)
    opts.picker.win.list = opts.picker.win.list or {}
    opts.picker.win.list.keys = vim.tbl_extend("force", opts.picker.win.list.keys or {}, macos_picker_keys)

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
