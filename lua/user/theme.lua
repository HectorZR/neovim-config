-- Colors derived from the active colorscheme, so every theme gets the same soft diff look.
local M = {}

M.LOGO_ROWS = 6

local function fg_of(groups)
  for _, name in ipairs(groups) do
    local fg = vim.api.nvim_get_hl(0, { name = name, link = false }).fg
    if fg then
      return fg
    end
  end
end

--- Mix `color` over `base`; `amount` goes from 0 (only base) to 1 (only color).
local function blend(color, base, amount)
  local function channel(shift)
    local c, b = math.floor(color / shift) % 256, math.floor(base / shift) % 256
    return math.floor(b + (c - b) * amount + 0.5) * shift
  end
  return channel(0x10000) + channel(0x100) + channel(1)
end

--- Dashboard colors: each logo letter fades down its rows, H into the color where Z starts.
local function apply_dashboard()
  -- only the color: some themes give FloatBorder a background that would patch the panel
  vim.api.nvim_set_hl(0, "UserDashboardBorder", { fg = fg_of({ "FloatBorder", "Comment" }) })
  local first = fg_of({ "Function" })
  local middle = fg_of({ "Keyword", "Statement" })
  local last = fg_of({ "Constant" })
  if not (first and middle and last) then
    return
  end
  for row = 1, M.LOGO_ROWS do
    local amount = (row - 1) / (M.LOGO_ROWS - 1)
    vim.api.nvim_set_hl(0, "UserDashboardH" .. row, { fg = blend(middle, first, amount) })
    vim.api.nvim_set_hl(0, "UserDashboardZ" .. row, { fg = blend(last, middle, amount) })
  end
end

function M.apply()
  apply_dashboard()
  local fallback = vim.o.background == "light" and 0xffffff or 0x1e1e2e
  local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg or fallback
  local add = fg_of({ "GitSignsAdd", "diffAdded", "Added" })
  local delete = fg_of({ "GitSignsDelete", "diffRemoved", "Removed" })
  local change = fg_of({ "GitSignsChange", "diffChanged", "Changed" })
  if not (add and delete and change) then
    return
  end

  local groups = {
    DiffAdd = { bg = blend(add, bg, 0.14) },
    DiffDelete = { bg = blend(delete, bg, 0.14) },
    DiffChange = { bg = blend(change, bg, 0.1) },
    DiffText = { bg = blend(change, bg, 0.3) },
    DiffTextAdd = { bg = blend(add, bg, 0.34) },
    -- the exact words that changed, in codediff and gitsigns
    UserDiffAddText = { bg = blend(add, bg, 0.34) },
    UserDiffDeleteText = { bg = blend(delete, bg, 0.34) },
    GitSignsAddInline = { bg = blend(add, bg, 0.34) },
    GitSignsDeleteInline = { bg = blend(delete, bg, 0.34) },
    GitSignsChangeInline = { bg = blend(change, bg, 0.3) },
  }
  for name, hl in pairs(groups) do
    vim.api.nvim_set_hl(0, name, hl)
  end
end

function M.setup()
  -- created before any plugin's handler, so codediff reads these colors when it rebuilds its own
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("user_theme", { clear = true }),
    callback = M.apply,
  })
end

return M
