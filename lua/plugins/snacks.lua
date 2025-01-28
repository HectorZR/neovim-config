return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
        bigfile = { enabled = true },
        dashboard = {
            enabled = true,
            preset = {
                header = [[
  ██╗   ██╗███████╗
  ██║   ██║╚══███╔╝
████████║  ███╔╝
██╔═══██║ ███╔╝
  ██║   ██║███████╗
  ╚═╝   ╚═╝╚══════╝
]],
            },
        },
        dim = {},
        notifier = {},
        input = {
            enabled = true,
            keys = {
            },
        },
        indent = { enabled = true },
        picker = { enabled = true },
        quickfile = { enabled = true },
        statuscolumn = { enabled = true },
        words = { enabled = true },
    },
    keys = {
        -- Fuzzy
        { "<leader>fb", function() Snacks.picker.buffers() end,                                 desc = "Buffers" },
        { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find Config File" },
        { "<leader>ff", function() Snacks.picker.files() end,                                   desc = "Find Files" },
        { "<leader>fg", function() Snacks.picker.git_files() end,                               desc = "Find Git Files" },
        { "<leader>fr", function() Snacks.picker.recent() end,                                  desc = "Recent" },
        -- LSP
        { "gd",         function() Snacks.picker.lsp_definitions() end,                         desc = "Goto Definition" },
        { "gr",         function() Snacks.picker.lsp_references() end,                          nowait = true,                  desc = "References" },
        { "gI",         function() Snacks.picker.lsp_implementations() end,                     desc = "Goto Implementation" },
        { "gy",         function() Snacks.picker.lsp_type_definitions() end,                    desc = "Goto T[y]pe Definition" },
        { "<leader>ss", function() Snacks.picker.lsp_symbols() end,                             desc = "LSP Symbols" },
        { "<F2>",       function() Snacks.rename.rename_file() end,                             desc = "Rename File" },
        -- Dim
        { "<leader>d",  function() Snacks.dim.enable() end,                                     desc = "Activate dim mode" },
        { "<leader>D",  function() Snacks.dim.disable() end,                                    desc = "Deactivate dim mode" },
        -- notifier
        { "<leader>nh", function() Snacks.notifier.show_history() end,                          desc = "Show notifier history" },
    }
}
