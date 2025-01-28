return {
    {
        "williamboman/mason.nvim",
        priority = 998,
        opts = {},
        keys = {
            {
                "<leader>m",
                function()
                    vim.cmd [[Mason]]
                end,
                desc = "Show Mason UI"
            },
        }
    },
    {
        "williamboman/mason-lspconfig.nvim",
        priority = 997,
        opts = {
            ensure_installed = {}
        }
    },
    {
        "neovim/nvim-lspconfig",
        priority = 996,
        config = function()
            local lspconfig = require("lspconfig")

            lspconfig.ts_ls.setup {}
            lspconfig.html.setup {}
            lspconfig.tailwindcss.setup {}
            lspconfig.eslint.setup {}
            lspconfig.emmet_language_server.setup {}
            lspconfig.lua_ls.setup {}
        end
    }
}
