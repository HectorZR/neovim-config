return {
    "nvim-lualine/lualine.nvim",
    opts = {
        sections = {
            lualine_y = {},
            lualine_z = {
                {
                    "progress",
                    separator = " ",
                    padding = { left = 1, right = 0 }
                },
                {
                    "location",
                    padding = { left = 0, right = 1 }
                },
            },

        }
    }
}
