-- Commits panel of the review tab: sits to the right of the codediff file list, in the bottom row.
-- It follows the file list: it appears, hides and goes away with it.
-- Choosing a row points that file list at it: "All changes" is everything since the branch was
-- created, committed or not; "Untracked changes" is the work not committed yet; a commit is just
-- that commit. This changes codediff's session data, so codediff is pinned in plugins/review.lua.
local M = {}

local FILETYPE = "codediff-commits"
local REFRESH_MS = 5000 -- how often to look for new commits
local MAX_AGE_S = 60 -- redraw at least this often, so dates like "2 minutes ago" stay right
local ns = vim.api.nvim_create_namespace("user.review_panel")
local commits = {} -- buffer -> commits on screen
local bases = {} -- buffer -> branch the commits are compared with
local shown = {} -- buffer -> { base, items } last drawn
local tab_states = {} -- tab -> { selected = nil (All changes) | UNCOMMITTED | OTHER | commit hash }
local EMPTY_TREE = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
local UNCOMMITTED = "uncommitted" -- value of `selected` for the "Untracked changes" row
local OTHER = "other" -- the tab opened on a comparison that matches no row
local FIRST_COMMIT_ROW = 4

local function find_windows(tab)
  local explorer, panel
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    local filetype = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
    if filetype == "codediff-explorer" then
      explorer = win
    elseif filetype == FILETYPE then
      panel = win
    end
  end
  return explorer, panel
end

--- The branch this work is compared with: origin's default branch, else main or master.
local function base_ref(cwd)
  local function git(args)
    local res = vim.system(vim.list_extend({ "git", "-C", cwd }, args), { text = true }):wait()
    return res.code == 0 and vim.trim(res.stdout or "") or nil
  end
  local origin = git({ "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD" })
  if origin and origin ~= "" then
    return origin
  end
  for _, ref in ipairs({ "origin/main", "origin/master", "main", "master" }) do
    if git({ "rev-parse", "--verify", "--quiet", ref }) then
      return ref
    end
  end
end

--- The commit this branch was created from.
local function fork_point(cwd, base)
  if not base then
    return nil
  end
  local res = vim.system({ "git", "-C", cwd, "merge-base", base, "HEAD" }, { text = true }):wait()
  return res.code == 0 and vim.trim(res.stdout) or nil
end

--- Selection state of a tab, starting from the comparison the tab was opened with.
local function tab_state(tab, buf)
  if tab_states[tab] then
    return tab_states[tab]
  end
  local session = require("codediff.ui.lifecycle").get_session(tab)
  local data = session and session.panel and session.panel.data
  if not data then
    return {}
  end
  local state = {}
  local working = data.target_revision == nil or data.target_revision == "WORKING"
  if not data.base_revision and working then
    state.selected = UNCOMMITTED
  elseif not (working and data.base_revision == fork_point(vim.fn.getcwd(), bases[buf])) then
    state.selected = OTHER
  end
  tab_states[tab] = state
  return state
end

local function draw(buf, base, items)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local state = tab_state(vim.api.nvim_get_current_tabpage(), buf)
  local all_selected = state.selected == nil
  local function marker(active)
    return { active and "● " or "  ", "Special" }
  end
  local title = base and ("Commits since %s (%d)"):format(base, #items) or ("Commits (%d)"):format(#items)
  local lines = {
    { { title, "Directory" } },
    { marker(all_selected), { "All changes", all_selected and "Title" or "Normal" } },
    {
      marker(state.selected == UNCOMMITTED),
      { "Untracked changes", state.selected == UNCOMMITTED and "Title" or "Normal" },
    },
  }
  for _, item in ipairs(items) do
    local line = { marker(state.selected == item.full), { item.hash .. " ", "SnacksPickerDimmed" } }
    Snacks.picker.highlight.extend(line, Snacks.picker.format.commit_message({ msg = item.subject }, {}))
    vim.list_extend(line, { { " " }, { item.date, "SnacksPickerGitDate" } })
    table.insert(lines, line)
  end
  local first_draw = shown[buf] == nil
  commits[buf], shown[buf] = items, { base = base, items = items }
  Snacks.picker.highlight.render(buf, ns, lines)
  local win = vim.fn.bufwinid(buf)
  if first_draw and win ~= -1 then
    vim.api.nvim_win_set_cursor(win, { state.selected == UNCOMMITTED and 3 or 2, 0 })
  end
end

local function read_log(cwd, range, cb)
  local cmd = { "git", "-C", cwd, "log", "-n", "50", "--format=%h%x09%H%x09%cr%x09%s" }
  vim.system(vim.list_extend(cmd, range), { text = true }, function(res)
    vim.schedule(function()
      local items = {}
      for line in (res.stdout or ""):gmatch("[^\n]+") do
        local hash, full, date, subject = line:match("^(.-)\t(.-)\t(.-)\t(.*)$")
        if hash then
          table.insert(items, { hash = hash, full = full, date = date, subject = subject })
        end
      end
      cb(items)
    end)
  end)
end

--- Reload the list in the background: the branch's own commits, or recent history on the base.
local function refresh(buf, cwd)
  local base = bases[buf]
  read_log(cwd, base and { base .. "..HEAD" } or {}, function(items)
    if #items > 0 or not base then
      return draw(buf, base, items)
    end
    read_log(cwd, {}, function(history)
      draw(buf, nil, history)
    end)
  end)
end

--- Point the file list of this tab at `comparison` and open its first file.
local function compare(tab, comparison)
  local lifecycle = require("codediff.ui.lifecycle")
  local session = lifecycle.get_session(tab)
  local data = session and session.panel and session.panel.name == "explorer" and session.panel.data
  if not data then
    return
  end
  data.base_revision = comparison.base
  data.target_revision = comparison.target
  data.source_revisions = comparison.source
  session.refresh:request({ full = true }, function()
    local view = lifecycle.get_panel_view(tab)
    local files = view and require("codediff.ui.explorer").get_all_files(view.tree) or {}
    if files[1] then
      view.on_file_select(files[1].data, { no_jump = true })
    else
      vim.notify("No file changes here", vim.log.levels.INFO, { title = "Review" })
    end
  end)
end

--- Show the row under the cursor: "All changes", "Untracked changes" or one commit.
local function select_row(buf)
  local tab = vim.api.nvim_get_current_tabpage()
  local row = vim.fn.line(".")
  local item = (commits[buf] or {})[row - FIRST_COMMIT_ROW + 1]
  if row < 2 or (row >= FIRST_COMMIT_ROW and not item) then
    return
  end
  local state = tab_state(tab, buf)
  tab_states[tab] = state
  local selected = item and item.full or (row == 3 and UNCOMMITTED or nil)
  if state.selected == selected then
    return
  end
  local comparison = {} -- no revisions: codediff compares the working tree with HEAD
  if item then
    local parent = vim.system({ "git", "rev-parse", "--verify", "--quiet", item.full .. "^" }, { text = true }):wait()
    -- a first commit has no parent: compare it with git's empty tree
    comparison = { base = parent.code == 0 and vim.trim(parent.stdout) or EMPTY_TREE, target = item.full }
  elseif selected == nil then
    local fork = fork_point(vim.fn.getcwd(), bases[buf])
    if fork then
      comparison = { base = fork, target = "WORKING", source = { original = fork, modified = "WORKING" } }
    end
  end
  state.selected = selected
  compare(tab, comparison)
  local last = shown[buf]
  if last then
    draw(buf, last.base, last.items)
  end
end

--- Move between the two windows of the bottom row.
---@param target "explorer"|"commits"
local function focus_panel(target)
  local explorer, panel = find_windows(vim.api.nvim_get_current_tabpage())
  local win = target == "explorer" and explorer or panel
  if win then
    vim.api.nvim_set_current_win(win)
  end
end

local function open_panel(explorer)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = FILETYPE
  vim.bo[buf].modifiable = false
  local width = math.floor(vim.api.nvim_win_get_width(explorer) * 0.45)
  local win = vim.api.nvim_open_win(buf, false, { split = "right", win = explorer, width = width })
  for option, value in pairs({
    number = false,
    relativenumber = false,
    signcolumn = "no",
    foldcolumn = "0",
    wrap = false,
    cursorline = true,
    winfixheight = true,
  }) do
    vim.wo[win][option] = value
  end
  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, desc = desc })
  end
  map("<CR>", function()
    select_row(buf)
  end, "Show these changes")
  map("R", function()
    refresh(buf, vim.fn.getcwd())
  end, "Refresh commits")
  map("q", "<cmd>tabclose<cr>", "Close review")
  map("h", function()
    focus_panel("explorer")
  end, "Go to file list")
  vim.keymap.set("n", "l", function()
    focus_panel("commits")
  end, { buffer = vim.api.nvim_win_get_buf(explorer), nowait = true, desc = "Go to commits" })
  bases[buf] = base_ref(vim.fn.getcwd())
  refresh(buf, vim.fn.getcwd())
end

--- Make the panel match the file list of the current tab.
local function sync()
  local tab = vim.api.nvim_get_current_tabpage()
  local explorer, panel = find_windows(tab)
  if explorer and not panel then
    open_panel(explorer)
  elseif panel and not explorer then
    vim.api.nvim_win_close(panel, true)
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("user_review_panel", { clear = true })
  local pending = false
  local function schedule_sync()
    if not pending then
      pending = true
      vim.schedule(function()
        pending = false
        sync()
      end)
    end
  end
  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinClosed", "TabEnter" }, { group = group, callback = schedule_sync })
  vim.api.nvim_create_autocmd("TabClosed", {
    group = group,
    callback = function()
      for tab in pairs(tab_states) do
        if not vim.api.nvim_tabpage_is_valid(tab) then
          tab_states[tab] = nil
        end
      end
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "CodeDiffOpen", "CodeDiffFileSelect" },
    callback = schedule_sync,
  })
  -- git writes logs/HEAD on every commit, checkout or reset: reading its time costs no process
  local git_dirs, last = {}, {}
  local function head_changed(buf, cwd)
    if git_dirs[cwd] == nil then
      local out = vim.fn.systemlist({ "git", "-C", cwd, "rev-parse", "--absolute-git-dir" })
      git_dirs[cwd] = vim.v.shell_error == 0 and out[1] or false
    end
    local stat = git_dirs[cwd] and vim.uv.fs_stat(git_dirs[cwd] .. "/logs/HEAD")
    local stamp = stat and ("%d.%d:%d"):format(stat.mtime.sec, stat.mtime.nsec, stat.size) or nil
    local now = os.time()
    local prev = last[buf]
    if stamp and prev and prev.stamp == stamp and now - prev.time < MAX_AGE_S then
      return false
    end
    last[buf] = { stamp = stamp, time = now }
    return true
  end
  local timer = assert(vim.uv.new_timer())
  timer:start(
    REFRESH_MS,
    REFRESH_MS,
    vim.schedule_wrap(function()
      local _, panel = find_windows(vim.api.nvim_get_current_tabpage())
      if panel then
        local buf, cwd = vim.api.nvim_win_get_buf(panel), vim.fn.getcwd()
        if head_changed(buf, cwd) then
          refresh(buf, cwd)
        end
      end
    end)
  )
end

return M
