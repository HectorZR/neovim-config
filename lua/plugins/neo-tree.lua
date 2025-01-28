return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
    },
    opts = function(_, opts)
        opts.window = {
            position = "float",
            toggle = true,
        }

        local function on_move(data)
            Snacks.rename.on_rename_file(data.source, data.destination)
        end
        local events = require("neo-tree.events")
        opts.event_handlers = opts.event_handlers or {}
        vim.list_extend(opts.event_handlers, {
            { event = events.FILE_MOVED,   handler = on_move },
            { event = events.FILE_RENAMED, handler = on_move },
        })
    end,
    keys = {
        {
            "<leader>e",
            function()
                vim.cmd [[Neotree]]
            end,
            desc = "Show workdir tree"
        },
    }
}
