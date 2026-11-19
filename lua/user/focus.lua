-- Marks the active window: the others hide their line numbers and current-line highlight.
-- The numbers take the background color, so the text doesn't shift when the focus moves.
local M = {}

local ns = vim.api.nvim_create_namespace("user.focus")

local function is_float(win)
  return vim.api.nvim_win_get_config(win).relative ~= ""
end

local function refresh()
  local current = vim.api.nvim_get_current_win()
  if is_float(current) then
    return -- a popup doesn't change which window you are working in
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if not is_float(win) then
      local active = win == current
      local win_ns = vim.api.nvim_get_hl_ns({ winid = win })
      -- octo uses its own namespace on its review windows
      if win_ns <= 0 or win_ns == ns then
        vim.api.nvim_win_set_hl_ns(win, active and 0 or ns)
      end
      if vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "" then
        vim.wo[win].cursorline = active
      end
    end
  end
end

local function apply_colors()
  local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
  local hidden = bg and { fg = bg } or { link = "NonText" }
  for _, name in ipairs({ "LineNr", "LineNrAbove", "LineNrBelow", "CursorLineNr" }) do
    vim.api.nvim_set_hl(ns, name, hidden)
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("user_focus", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = apply_colors })
  vim.api.nvim_create_autocmd({ "WinEnter", "TabEnter", "BufWinEnter" }, { group = group, callback = refresh })
end

return M
