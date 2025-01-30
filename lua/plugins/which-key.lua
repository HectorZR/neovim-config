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
            "<leader>s",
            function()
                vim.cmd [[w]]
            end,
            desc = "Save buffer"
        },
        {
            "<leader>as",
            function()
                vim.cmd [[wa]]
            end,
            desc = "Save all buffers"
        },
        {
            "<leader>Q",
            function()
                vim.cmd [[qa]]
            end,
            desc = "Close Neovim"
        },
        {
            "<leader>nn",
            function()
                vim.cmd [[noh]]
            end,
            desc = "Clear highlights"
        },
        {
            "<S-h>",
            function()
                vim.cmd [[bprevious]]
            end,
            desc = "Switch to previous buffer"
        },
        {
            "<S-l>",
            function()
                vim.cmd [[bnext]]
            end,
            desc = "Switch to next buffer"
        }
    },
}
