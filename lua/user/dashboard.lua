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
local LABEL_WIDTH = 13 -- icon and name
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

--- Icon, label, value and value color of each row, for the current directory.
local function rows()
  local cwd = vim.fn.getcwd()
  local worktrees = require("user.worktrees").list(cwd)
  if not worktrees or not worktrees[1] then
    return { { "\u{f07b}", "folder", vim.fn.fnamemodify(cwd, ":~"), "String" } }
  end
  -- the worktree list already has the branch of the worktree we're in, so no extra git call
  local real = vim.fs.normalize(vim.uv.fs_realpath(cwd) or cwd)
  local here
  for _, wt in ipairs(worktrees) do
    if (real == wt.path or vim.startswith(real, wt.path .. "/")) and (not here or #wt.path > #here.path) then
      here = wt
    end
  end
  local branch = here and here.branch ~= "" and here.branch or git({ "branch", "--show-current" }, cwd)
  if not branch or branch == "" then
    branch = "detached (" .. (git({ "rev-parse", "--short", "HEAD" }, cwd) or "?") .. ")"
  end
  return {
    { "\u{f401}", "repo", vim.fn.fnamemodify(worktrees[1].path, ":t"), "String" },
    { "\u{e725}", "branch", branch, "Keyword" },
    { "\u{f1bb}", "worktrees", tostring(#worktrees), "Constant" },
  }
end

--- Row with the plugin updates waiting, if any: the statusline no longer shows them.
local function updates_row()
  local ok, checker = pcall(require, "lazy.manage.checker")
  local count = ok and #checker.updated or 0
  if count > 0 then
    return { "\u{f487}", "updates", count .. (count == 1 and " plugin" or " plugins"), "DiagnosticWarn" }
  end
end

--- Redraw the dashboard once lazy has compared the plugins, which happens after it opens.
local watching = false
local function watch_updates()
  if watching then
    return
  end
  watching = true
  vim.defer_fn(function()
    if vim.bo.filetype == "snacks_dashboard" and updates_row() then
      Snacks.dashboard.update()
    end
  end, 500)
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
  local updates = updates_row()
  if updates then
    table.insert(data, updates)
  end
  watch_updates()
  local hello = greeting()
  local info = math.max(MIN_INFO, vim.fn.strdisplaywidth(hello))
  for _, row in ipairs(data) do
    info = math.max(info, LABEL_WIDTH + vim.fn.strdisplaywidth(row[3]))
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
      { row[1] .. " ", hl = row[4] },
      { pad(row[2], LABEL_WIDTH - 2), hl = "Comment" },
      { pad(fit(row[3], info - LABEL_WIDTH), info - LABEL_WIDTH), hl = row[4] },
    })
  end

  local title_width = vim.fn.strdisplaywidth("─ hector@zurga ")
  local items = {
    {
      align = "center",
      text = {
        { "╭─ ", hl = "UserDashboardBorder" },
        { "hector", hl = "Function" },
        { "@", hl = "Comment" },
        { "zurga", hl = "Keyword" },
        { " " .. ("─"):rep(width - title_width) .. "╮", hl = "UserDashboardBorder" },
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
