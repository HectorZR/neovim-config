-- Remembers the colorscheme you pick, and keeps the light or dark mode you chose when switching themes.
-- Without this, a theme that only has a light variant leaves 'background' light for the next theme.
local M = {}

local DEFAULT = "catppuccin-frappe"
local file = vim.fn.stdpath("state") .. "/colorscheme.json"

local preferred = "dark" -- mode you set yourself with :set background
local loading = false -- a colorscheme is changing 'background' on its own
local restoring = false -- loading the saved colorscheme with its saved mode

local function read()
  local ok, data = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(file), "\n"))
  end)
  return ok and type(data) == "table" and data or {}
end

local function save()
  local data = { name = vim.g.colors_name, background = vim.o.background, preferred = preferred }
  pcall(vim.fn.writefile, { vim.json.encode(data) }, file)
end

--- Load the last colorscheme, or the default one. Used as LazyVim's `colorscheme` option.
function M.load()
  local saved = read()
  preferred = saved.preferred or preferred
  loading, restoring = true, true
  vim.o.background = saved.background or preferred
  if not saved.name or not pcall(vim.cmd.colorscheme, saved.name) then
    vim.cmd.colorscheme(DEFAULT)
  end
  loading, restoring = false, false
end

function M.setup()
  local group = vim.api.nvim_create_augroup("user_colorscheme", { clear = true })
  vim.api.nvim_create_autocmd("ColorSchemePre", {
    group = group,
    callback = function(ev)
      if restoring or ev.match == vim.g.colors_name then
        return -- the saved theme, or the same theme reloading after :set background
      end
      loading = true
      if vim.o.background ~= preferred then
        -- without a current theme, changing 'background' doesn't reload the old one first
        vim.g.colors_name = nil
        vim.o.background = preferred
      end
    end,
  })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      loading = false
      save()
    end,
  })
  vim.api.nvim_create_autocmd("OptionSet", {
    group = group,
    pattern = "background",
    callback = function()
      if not loading then
        preferred = vim.v.option_new
        save()
      end
    end,
  })
end

return M
