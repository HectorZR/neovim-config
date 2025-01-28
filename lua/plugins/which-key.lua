return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        preset = 'helix',
    },
    keys = {
        {
            "<leader>l",
            function()
                vim.cmd [[Lazy]]
            end,
            desc = "Load lazy.nvim"
        },
        {
            "<leader>q",
            function()
                vim.cmd [[bdelete]]
            end,
            desc = "Close buffer"
        },
        {
            "<leader>w",
            function()
                vim.cmd [[w]]
            end,
            desc = "Save buffer"
        },
        {
            "<leader>Q",
            function()
                vim.cmd [[qa]]
            end,
            desc = "Close Neovim"
        }
    },
}
