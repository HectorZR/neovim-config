-- Line numbers in two columns: the real number and the distance from the cursor.
-- Signs and folds still come from the snacks status column.
local M = {}

function M.get()
  if not package.loaded.snacks then
    return ""
  end
  local column = require("snacks.statuscolumn").get()
  local win = vim.g.statusline_winid
  if not (vim.wo[win].number and vim.wo[win].relativenumber) then
    return column
  end
  local width = #tostring(vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(win)))
  local numbers = ("%%%%=%" .. width .. "d %" .. width .. "d "):format(vim.v.lnum, vim.v.relnum)
  return (column:gsub("%%=%d+ ", numbers, 1))
end

return M
