-- Dashboard greeting: the HZ logo beside the time of day and the repository of the current directory.
local M = {}

local NAME = "Hector"
local LOGO = {
  "██╗  ██╗███████╗",
  "██║  ██║╚══███╔╝",
  "███████║  ███╔╝ ",
  "██╔══██║ ███╔╝  ",
  "██║  ██║███████╗",
  "╚═╝  ╚═╝╚══════╝",
}
local LOGO_WIDTH = 16
local GAP = "   "
local MIN_INFO, MAX_INFO = 24, 33 -- the whole panel has to fit the dashboard's 60 columns
local LABEL_WIDTH = 11
local PADDING = 2

local function greeting()
  local hour = tonumber(os.date("%H"))
  if hour >= 5 and hour < 12 then
    return "Good morning, " .. NAME
  elseif hour >= 12 and hour < 18 then
    return "Good afternoon, " .. NAME
  end
  return "Good evening, " .. NAME
end

local function git(args, cwd)
  local out = vim.fn.systemlist(vim.list_extend({ "git", "-C", cwd }, args))
  return vim.v.shell_error == 0 and out[1] or nil
end

--- Label and value of each row, for the current directory.
local function rows()
  local cwd = vim.fn.getcwd()
  local worktrees = require("user.worktrees").list(cwd)
  if not worktrees or not worktrees[1] then
    return { { "folder", vim.fn.fnamemodify(cwd, ":~") } }
  end
  local branch = git({ "branch", "--show-current" }, cwd)
  if not branch or branch == "" then
    branch = "detached (" .. (git({ "rev-parse", "--short", "HEAD" }, cwd) or "?") .. ")"
  end
  return {
    { "repo", vim.fn.fnamemodify(worktrees[1].path, ":t") },
    { "branch", branch },
    { "worktrees", tostring(#worktrees) },
  }
end

local function fit(text, width)
  if vim.fn.strdisplaywidth(text) <= width then
    return text
  end
  return vim.fn.strcharpart(text, 0, width - 1) .. "…"
end

local function pad(text, width)
  return text .. (" "):rep(width - vim.fn.strdisplaywidth(text))
end

--- Section for snacks.dashboard: the panel as centered lines.
function M.section()
  local data = rows()
  local hello = greeting()
  local info = math.max(MIN_INFO, vim.fn.strdisplaywidth(hello))
  for _, row in ipairs(data) do
    info = math.max(info, LABEL_WIDTH + vim.fn.strdisplaywidth(row[2]))
  end
  info = math.min(info, MAX_INFO)
  local inner = LOGO_WIDTH + #GAP + info
  local width = inner + 2 * PADDING
  local margin = (" "):rep(PADDING)

  local function line(chunks)
    local text = { { "│" .. margin, hl = "UserDashboardBorder" } }
    vim.list_extend(text, chunks)
    table.insert(text, { margin .. "│", hl = "UserDashboardBorder" })
    return { align = "center", text = text }
  end
  local blank = line({ { (" "):rep(inner) } })

  -- what goes to the right of each logo row
  local right = { { { pad(hello, info), hl = "Title" } }, { { (" "):rep(info) } } }
  for _, row in ipairs(data) do
    table.insert(right, {
      { pad(row[1], LABEL_WIDTH), hl = "Comment" },
      { pad(fit(row[2], info - LABEL_WIDTH), info - LABEL_WIDTH), hl = "SnacksDashboardSpecial" },
    })
  end

  local title_width = vim.fn.strdisplaywidth("─ hector@zurga ")
  local items = {
    {
      align = "center",
      text = {
        { "╭─ hector@zurga " .. ("─"):rep(width - title_width) .. "╮", hl = "UserDashboardBorder" },
      },
    },
    blank,
  }
  for i, logo in ipairs(LOGO) do
    local chunks = {
      { vim.fn.strcharpart(logo, 0, LOGO_WIDTH / 2), hl = "UserDashboardH" .. i },
      { vim.fn.strcharpart(logo, LOGO_WIDTH / 2), hl = "UserDashboardZ" .. i },
      { GAP },
    }
    vim.list_extend(chunks, right[i] or { { (" "):rep(info) } })
    table.insert(items, line(chunks))
  end
  table.insert(items, blank)
  table.insert(
    items,
    { align = "center", padding = 2, text = { { "╰" .. ("─"):rep(width) .. "╯", hl = "UserDashboardBorder" } } }
  )
  return items
end

return M
