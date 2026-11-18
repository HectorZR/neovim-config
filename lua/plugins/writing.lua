-- Prose: rendered markdown (agent plans, docs) and grammar checking in Spanish/English.
local languages = { "es", "en-US" }

--- Switch the grammar language of the running ltex server.
local function toggle_language()
  local clients = vim.lsp.get_clients({ name = "ltex_plus" })
  if #clients == 0 then
    return vim.notify("ltex is not running in this buffer", vim.log.levels.WARN)
  end
  for _, client in ipairs(clients) do
    local ltex = client.settings.ltex
    ltex.language = ltex.language == languages[1] and languages[2] or languages[1]
    client:notify("workspace/didChangeConfiguration", { settings = client.settings })
    vim.notify("Grammar language: " .. ltex.language, vim.log.levels.INFO, { title = "ltex" })
  end
end

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    opts = {
      code = { sign = false, width = "block", right_pad = 1 },
      heading = { sign = false, icons = {} },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      Snacks.toggle({
        name = "Render Markdown",
        get = require("render-markdown").get,
        set = require("render-markdown").set,
      }):map("<leader>um")
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ltex_plus = {
          filetypes = { "markdown", "text", "gitcommit" },
          settings = { ltex = { language = languages[1] } },
          keys = {
            { "<leader>cG", toggle_language, desc = "Toggle Grammar Language (es/en)" },
          },
        },
      },
    },
  },
}
