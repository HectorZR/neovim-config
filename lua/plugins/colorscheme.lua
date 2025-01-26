return {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 999,
    config = function()
        vim.cmd([[colorscheme tokyonight]])
    end,
    opts = { style = "night" },
}
