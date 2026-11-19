return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.picker = opts.picker or {}
    opts.picker.sources = opts.picker.sources or {}
    -- macOS: Option+H sends ˙ (U+02D9), Option+I sends ˆ (U+02C6) instead of ESC-prefixed
    -- sequences. Map these Unicode chars to the same toggle actions as <a-h> / <a-i>.
    -- On Linux, Alt+H/I send ESC+h/i correctly so <a-h>/<a-i> still handle those.
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
    -- Ported from the old fzf-lua fd_opts: show hidden files, follow symlinks, skip build/vendor dirs
    opts.picker.sources.files = vim.tbl_deep_extend("force", opts.picker.sources.files or {}, {
      hidden = true,
      follow = true,
      exclude = {
        ".git",
        "node_modules",
        "dist",
        "build",
        ".next",
        ".nuxt",
        "coverage",
        ".cache",
        "__pycache__",
        ".venv",
        "vendor",
      },
    })
    opts.picker.sources.projects = vim.tbl_deep_extend("force", opts.picker.sources.projects or {}, {
      dev = { "~/dev", "~/projects", "~/Developer" },
    })

    -- guides only for the block under the cursor, in the active window
    opts.indent = vim.tbl_deep_extend("force", opts.indent or {}, {
      indent = { only_scope = true, only_current = true },
    })

    opts.image = opts.image or {}
    opts.image.enabled = true

    opts.dashboard = opts.dashboard or {}
    opts.dashboard.enabled = true
    opts.dashboard.preset = opts.dashboard.preset or {}
    opts.dashboard.sections = {
      function()
        return require("user.dashboard").section()
      end,
      { section = "keys", padding = 1 },
      { section = "startup" },
    }
    -- review shortcuts, right after the file ones
    local keys = opts.dashboard.preset.keys or {}
    local position = #keys + 1
    for i, item in ipairs(keys) do
      if item.key == "r" then
        position = i + 1
      end
    end
    table.insert(keys, position, {
      icon = "\u{f126} ",
      key = "w",
      desc = "Worktrees",
      action = ":lua require('user.worktrees').pick()",
    })
    table.insert(keys, position + 1, {
      icon = "\u{f407} ",
      key = "P",
      desc = "Pull Requests",
      action = ":lua Snacks.picker.gh_pr()",
    })
    opts.dashboard.preset.keys = keys
  end,
}
