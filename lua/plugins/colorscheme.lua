return {
    -- "folke/tokyonight.nvim",
    'navarasu/onedark.nvim',
    lazy = false,
    priority = 999,
    config = function()
        -- vim.cmd([[colorscheme tokyonight]])
        vim.cmd([[colorscheme onedark]])
    end,
    opts = { style = "dark" },
}
