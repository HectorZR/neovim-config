-- Keeps side-by-side diffs aligned when virtual lines are added to one side.
-- Every virtual line needs an equally tall blank one at the matching row of the other window.
local M = {}

--- Screen rows used from the top of the buffer through `line` (fillers and virtual lines included).
local function rows_through(win, line)
  if line <= 0 then
    return 0
  end
  return vim.api.nvim_win_text_height(win, { start_row = 0, end_row = line - 1 }).all
end

--- Line of `other` shown at the same row as `line` of `win`.
---@return integer line 1-based line in `other`
---@return boolean above the row is a filler above that line, so padding must go above it
function M.counterpart(win, line, other)
  local target = rows_through(win, line)
  local low, high = 1, vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(other))
  while low < high do
    local mid = math.floor((low + high) / 2)
    if rows_through(other, mid) >= target then
      high = mid
    else
      low = mid + 1
    end
  end
  return low, rows_through(other, low) > target
end

--- Add `count` blank virtual lines to `other`, level with `line` of `win`.
function M.pad(ns, win, line, other, count)
  local target, above = M.counterpart(win, line, other)
  local blank = {}
  for i = 1, count do
    blank[i] = { { " ", "Normal" } }
  end
  return {
    buf = vim.api.nvim_win_get_buf(other),
    row = target - 1,
    opts = { virt_lines = blank, virt_lines_above = above },
    ns = ns,
  }
end

function M.apply(pad)
  vim.api.nvim_buf_set_extmark(pad.buf, pad.ns, pad.row, 0, pad.opts)
end

return M
