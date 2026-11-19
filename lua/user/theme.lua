-- Colors derived from the active colorscheme, so every theme gets the same soft diff look.
local M = {}

M.LOGO_ROWS = 6

-- Used when the theme doesn't define them: codediff would otherwise fall back to fixed colors
-- and which-key loses its link when a colorscheme clears the highlights.
local LINKS = {
  CodeDiffMoveFrom = "Function",
  CodeDiffMoveTo = "Function",
  CodeDiffFiller = "NonText",
  WhichKeyBorder = "FloatBorder",
}

local function fg_of(groups)
  for _, name in ipairs(groups) do
    local fg = vim.api.nvim_get_hl(0, { name = name, link = false }).fg
    if fg then
      return fg
    end
  end
end

-- floating windows share the editor background, so their rounded border is what frames them
local FLOATS = {
  "NormalFloat",
  "FloatBorder",
  "FloatTitle",
  "Pmenu",
  "BlinkCmpMenu",
  "BlinkCmpMenuBorder",
  "BlinkCmpDoc",
  "BlinkCmpDocBorder",
  "BlinkCmpDocSeparator",
  "BlinkCmpSignatureHelp",
  "BlinkCmpSignatureHelpBorder",
  "WhichKeyNormal",
  "WhichKeyBorder",
  "WhichKeyTitle",
  "NoiceCmdlinePopup",
  "NoiceCmdlinePopupBorder",
  "NoicePopup",
  "NoicePopupBorder",
  "NoicePopupmenu",
  "NoicePopupmenuBorder",
}

--- First background the theme defines: transparent themes have none on Normal.
local function background()
  for _, name in ipairs({ "Normal", "NormalFloat", "Pmenu", "StatusLine" }) do
    local bg = vim.api.nvim_get_hl(0, { name = name, link = false }).bg
    if bg then
      return bg
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

local function apply_floats()
  local editor = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
  local fallback_border = fg_of({ "Function", "Comment" })
  for _, name in ipairs(FLOATS) do
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    if hl.bg then
      -- themes with solid floats hide the border by painting it like the background
      if name:match("Border$") and (not hl.fg or hl.fg == hl.bg) then
        hl.fg = fallback_border
      end
      hl.bg = editor
      vim.api.nvim_set_hl(0, name, hl)
    end
  end
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
  apply_floats()
  apply_dashboard()
  for name, target in pairs(LINKS) do
    vim.api.nvim_set_hl(0, name, { link = target, default = true })
  end
  local bg = background()
  local add = fg_of({ "GitSignsAdd", "diffAdded", "Added" })
  local delete = fg_of({ "GitSignsDelete", "diffRemoved", "Removed" })
  local change = fg_of({ "GitSignsChange", "diffChanged", "Changed" })
  if not (bg and add and delete and change) then
    return -- keep the theme's own diff colors
  end

  local separator = fg_of({ "Comment" })
  if separator then
    vim.api.nvim_set_hl(0, "WinSeparator", { fg = blend(separator, bg, 0.3) })
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
