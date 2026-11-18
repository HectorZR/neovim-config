-- Minimal statusline built on Neovim 0.12 native helpers (replaces lualine).
-- Layout: MODE  branch  file [flags] ........ progress  diagnostics  line:col pct
local M = {}

local modes = {
  n = { "NORMAL", "StlModeNormal" },
  i = { "INSERT", "StlModeInsert" },
  v = { "VISUAL", "StlModeVisual" },
  V = { "V-LINE", "StlModeVisual" },
  ["\22"] = { "V-BLOCK", "StlModeVisual" },
  c = { "COMMAND", "StlModeCommand" },
  R = { "REPLACE", "StlModeReplace" },
  t = { "TERMINAL", "StlModeCommand" },
  s = { "SELECT", "StlModeVisual" },
  S = { "S-LINE", "StlModeVisual" },
}

local function set_hl()
  local function fg(name)
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    return hl.fg
  end
  local bg = vim.api.nvim_get_hl(0, { name = "StatusLine", link = false }).bg
  local map = {
    StlModeNormal = fg("Function"),
    StlModeInsert = fg("String"),
    StlModeVisual = fg("Statement"),
    StlModeCommand = fg("Constant"),
    StlModeReplace = fg("DiagnosticError"),
  }
  for name, color in pairs(map) do
    vim.api.nvim_set_hl(0, name, { fg = color, bg = bg, bold = true })
  end
  vim.api.nvim_set_hl(0, "StlBranch", { fg = fg("Special"), bg = bg })
end

function M.mode()
  local m = modes[vim.api.nvim_get_mode().mode:sub(1, 1)] or { vim.api.nvim_get_mode().mode, "StlModeNormal" }
  return ("%%#%s# %s %%*"):format(m[2], m[1])
end

function M.branch()
  local head = vim.b.gitsigns_head
  if not head or head == "" then
    return ""
  end
  return ("%%#StlBranch# %s%%* "):format(head)
end

function M.render()
  return table.concat({
    M.mode(),
    " ",
    M.branch(),
    "%<%{expand('%:~:.')} %h%w%m%r",
    "%=",
    "%{% v:lua.vim.ui.progress_status() %} ",
    '%{% luaeval(\'next(vim.diagnostic.count()) and vim.diagnostic.status() .. " " or ""\') %}',
    "%l:%c %P ",
  })
end

function M.setup()
  set_hl()
  vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })
  vim.o.statusline = "%!v:lua.require('user.statusline').render()"
end

return M
