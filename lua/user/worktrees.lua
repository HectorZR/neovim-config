-- Git worktrees as tabs: each worktree lives in its own tab with a tab-local cwd (:tcd).
-- `git worktree list` already returns every worktree wherever it lives
-- (sibling dirs, .worktrees/, .claude/worktrees/), so no path scanning is needed.
local M = {}

local function git(args, cwd)
  local cmd = { "git" }
  if cwd then
    vim.list_extend(cmd, { "-C", cwd })
  end
  vim.list_extend(cmd, args)
  local out = vim.fn.systemlist(cmd)
  return vim.v.shell_error == 0 and out or nil
end

local function normalize(path)
  return vim.fs.normalize(vim.fn.fnamemodify(path, ":p")):gsub("/$", "")
end

--- Worktrees of the repo containing `cwd` (defaults to the current tab cwd).
---@return {path:string, branch:string, head:string, main:boolean, locked:boolean}[]?
function M.list(cwd)
  local out = git({ "worktree", "list", "--porcelain" }, cwd or vim.fn.getcwd())
  if not out then
    return nil
  end
  local items, cur = {}, nil
  for _, line in ipairs(out) do
    local key, val = line:match("^(%S+)%s?(.*)$")
    if key == "worktree" then
      cur = { path = normalize(val), branch = "", head = "", main = #items == 0, locked = false }
      table.insert(items, cur)
    elseif cur and key == "HEAD" then
      cur.head = val:sub(1, 7)
    elseif cur and key == "branch" then
      cur.branch = val:gsub("^refs/heads/", "")
    elseif cur and key == "detached" then
      cur.branch = "(detached " .. cur.head .. ")"
      cur.detached = true
    elseif cur and key == "locked" then
      cur.locked = true
    elseif cur and key == "bare" then
      cur.bare = true
    end
  end
  return vim.tbl_filter(function(i)
    return not i.bare
  end, items)
end

--- Dirty file count and ahead/behind upstream for a worktree.
function M.status(path)
  local st = git({ "status", "--porcelain" }, path) or {}
  local ab = git({ "rev-list", "--left-right", "--count", "@{upstream}...HEAD" }, path)
  local behind, ahead
  if ab and ab[1] then
    behind, ahead = ab[1]:match("(%d+)%s+(%d+)")
  end
  return { dirty = #st, ahead = tonumber(ahead), behind = tonumber(behind) }
end

--- The octo PR review open in a tab, if any.
local function octo_review(tab)
  local reviews = package.loaded["octo.reviews"]
  return reviews and reviews.reviews[tostring(tab)] or nil
end

--- Diff tabs inherit the cwd of their worktree, so they must not count as its tab.
local function is_diff_tab(tab)
  if octo_review(tab) then
    return true
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype:match("^codediff") or vim.api.nvim_buf_get_name(buf):match("^codediff://") then
      return true
    end
  end
  return false
end

--- Tab whose tab-local cwd is `path`, ignoring diff tabs.
function M.find_tab(path)
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local nr = vim.api.nvim_tabpage_get_number(tab)
    if not is_diff_tab(tab) and normalize(vim.fn.getcwd(-1, nr)) == path then
      return tab
    end
  end
end

--- Focus the tab of a worktree, creating it (tab + :tcd) if needed.
function M.open(path)
  path = normalize(path)
  local tab = M.find_tab(path)
  if tab then
    vim.api.nvim_set_current_tabpage(tab)
  else
    -- reuse the current tab if it is still an empty startup tab
    local empty = vim.fn.tabpagenr("$") == 1 and vim.fn.bufname() == "" and not vim.bo.modified
    if not empty then
      vim.cmd("tabnew")
    end
    vim.cmd.tcd(vim.fn.fnameescape(path))
    vim.schedule(function()
      Snacks.picker.files({ cwd = path })
    end)
  end
  vim.api.nvim_exec_autocmds("User", { pattern = "WorktreeSwitched", data = { path = path } })
end

local function main_path()
  local list = M.list()
  return list and list[1] and list[1].path
end

--- Create a worktree (new or existing branch). Default location: sibling dir `<repo>-<branch>`.
function M.create(on_done)
  local main = main_path()
  if not main then
    return vim.notify("Not inside a git repository", vim.log.levels.WARN)
  end
  vim.ui.input({ prompt = "Branch (new or existing): " }, function(branch)
    if not branch or branch == "" then
      return
    end
    local default = main .. "-" .. branch:gsub("/", "-")
    vim.ui.input({ prompt = "Path: ", default = default, completion = "dir" }, function(path)
      if not path or path == "" then
        return
      end
      path = vim.fn.expand(path)
      local exists = git({ "rev-parse", "--verify", "--quiet", "refs/heads/" .. branch }, main)
      local args = exists and { "worktree", "add", path, branch } or { "worktree", "add", "-b", branch, path }
      local out = vim.fn.system(vim.list_extend({ "git", "-C", main }, args))
      if vim.v.shell_error ~= 0 then
        return vim.notify(out, vim.log.levels.ERROR, { title = "git worktree add" })
      end
      M.open(path)
      if on_done then
        on_done(path)
      end
    end)
  end)
end

--- Remove a worktree after confirmation; closes its tab.
function M.remove(item, on_done)
  if item.main then
    return vim.notify("Can't remove the main worktree", vim.log.levels.WARN)
  end
  local st = M.status(item.path)
  local msg = ("Remove worktree %s (%s)?"):format(item.path, item.branch)
  if st.dirty > 0 then
    msg = msg .. ("\n%d uncommitted change(s) will be LOST."):format(st.dirty)
  end
  if vim.fn.confirm(msg, "&Yes\n&No", 2) ~= 1 then
    return
  end
  local main = main_path() or vim.fn.getcwd()
  local tab = M.find_tab(item.path)
  if tab and #vim.api.nvim_list_tabpages() > 1 then
    vim.cmd.tabclose(vim.api.nvim_tabpage_get_number(tab))
  elseif tab then
    -- last tab: don't stay inside a directory that is about to disappear
    vim.cmd("silent! %bdelete")
    vim.cmd.tcd(vim.fn.fnameescape(main))
  end
  local args = { "worktree", "remove", item.path }
  if st.dirty > 0 then
    table.insert(args, "--force")
  end
  local out = vim.fn.system(vim.list_extend({ "git", "-C", main }, args))
  if vim.v.shell_error ~= 0 then
    return vim.notify(out, vim.log.levels.ERROR, { title = "git worktree remove" })
  end
  vim.notify("Removed " .. item.path, vim.log.levels.INFO, { title = "Worktrees" })
  if on_done then
    on_done()
  end
end

-- open PRs per repo, so the panel shows the last known ones while it refreshes
local pr_cache = {}

--- Run a gh command in `cwd`; cb(decoded_json) on the main loop, cb(nil) when it fails.
local function gh_json(args, cwd, cb)
  if vim.fn.executable("gh") == 0 then
    return cb(nil)
  end
  vim.system(vim.list_extend({ "gh" }, args), { cwd = cwd, text = true }, function(res)
    vim.schedule(function()
      local ok, data = pcall(vim.json.decode, res.stdout or "")
      cb(res.code == 0 and ok and data or nil)
    end)
  end)
end

--- The open PR of a worktree: by branch, or by commit when HEAD is detached. Forks never match,
--- their branch names say nothing about ours.
local function find_pr(prs, wt)
  for _, pr in ipairs(prs) do
    local same = wt.detached and wt.head ~= "" and pr.headRefOid:sub(1, #wt.head) == wt.head
      or pr.headRefName == wt.branch
    if same and not pr.isCrossRepository then
      return pr
    end
  end
end

--- "success" | "failure" | "pending" | "skipped" for one entry of statusCheckRollup.
local function check_state(check)
  local result = check.state
  if check.__typename == "CheckRun" then
    result = check.status == "COMPLETED" and check.conclusion or "PENDING"
  end
  local states =
    { SUCCESS = "success", SKIPPED = "skipped", NEUTRAL = "skipped", PENDING = "pending", EXPECTED = "pending" }
  return states[result] or "failure"
end

--- Overall state of a PR's checks, the worst one first.
local function checks_state(pr)
  local found = {}
  for _, check in ipairs(pr.details and pr.details.statusCheckRollup or {}) do
    found[check_state(check)] = true
  end
  return found.failure and "failure" or found.pending and "pending" or found.success and "success" or nil
end

local function pr_highlight(pr)
  local details = pr.details or {}
  local checks = checks_state(pr)
  if pr.isDraft then
    return "SnacksGhPrDraft"
  elseif checks == "failure" or pr.reviewDecision == "CHANGES_REQUESTED" or details.mergeable == "CONFLICTING" then
    return "SnacksGhCheckFailure"
  elseif checks == "pending" then
    return "SnacksGhCheckPending"
  elseif pr.reviewDecision == "APPROVED" then
    return "SnacksGhReviewApproved"
  end
  return "SnacksGhPrClean"
end

--- The PR as a snacks.gh item, so the snacks PR renderer can draw it.
local function gh_item(pr)
  local raw = vim.tbl_extend("force", pr, pr.details or {})
  raw.details, raw.state = nil, "OPEN"
  raw.mergeable = raw.mergeable == "MERGEABLE" or nil
  raw.statusCheckRollup = vim.tbl_map(function(check)
    return {
      __typename = "CheckRun",
      workflowName = check.workflowName or "",
      name = check.name or check.context or "",
      status = "COMPLETED",
      conclusion = check_state(check):upper(),
    }
  end, pr.details and pr.details.statusCheckRollup or {})
  local item = require("snacks.gh.item").new(raw, { type = "pr" })
  item.status = pr.isDraft and "draft" or "open"
  return item
end

local function prop(name, value)
  local line = { { name, "SnacksGhLabel" }, { ":", "SnacksGhDelim" }, { " " } }
  Snacks.picker.highlight.extend(line, value)
  return line
end

local function pr_preview(item, lines)
  local H, config = Snacks.picker.highlight, require("snacks.gh").config()
  local pr = item.pr
  if not pr then
    local empty = { loading = "Loading…", none = "No open PR", unavailable = "Not available (is gh logged in?)" }
    table.insert(lines, { { vim.fs.basename(item.wt.path), "Title" } })
    table.insert(lines, {})
    table.insert(lines, prop("Pull Request", { { empty[item.pr_state], "SnacksPickerDimmed" } }))
    return
  end
  local title = Snacks.picker.format.commit_message({ msg = pr.title }, {})
  vim.list_extend(title, { { " " }, { "#" .. pr.number, "SnacksPickerDimmed" } })
  vim.list_extend(lines, { title, {} })
  local gh = gh_item(pr)
  for _, field in ipairs(require("snacks.gh.render").props) do
    local ok, value = pcall(field.hl, gh, config)
    if ok and value and #value > 0 then
      table.insert(lines, prop(field.name, value))
    end
  end
  local reviews = {
    APPROVED = { "approved", "Approved", "SnacksGhReviewApproved" },
    CHANGES_REQUESTED = { "changes_requested", "Changes requested", "SnacksGhReviewChangesRequested" },
    REVIEW_REQUIRED = { "pending", "Review required", "SnacksGhReviewPending" },
  }
  local review = reviews[pr.reviewDecision]
  if review then
    table.insert(lines, prop("Review", H.badge(config.icons.review[review[1]] .. review[2], review[3])))
  end
  table.insert(lines, prop("Link", { { pr.url, "@markup.link" } }))
end

local function status_preview(item, lines)
  local H, config = Snacks.picker.highlight, require("snacks.gh").config()
  if not item.status then
    table.insert(lines, prop("Git", { { "Loading…", "SnacksPickerDimmed" } }))
    return
  end
  local header = item.status[1]
  local tracking = header:gsub("%s+%[.*%]$", "")
  local branch, upstream = tracking:match("^(.-)%.%.%.(.+)$")
  local value = { { branch or tracking, "SnacksGhBranch" } }
  if upstream then
    vim.list_extend(value, { { " → ", "SnacksGhDelim" }, { upstream, "SnacksGhBranch" } })
  end
  if item.st.ahead then
    vim.list_extend(value, { { " " }, { "↑" .. item.st.ahead, "SnacksGhAdditions" } })
  end
  if item.st.behind then
    vim.list_extend(value, { { " " }, { "↓" .. item.st.behind, "SnacksGhDeletions" } })
  end
  table.insert(lines, prop("Branch", value))
  if item.st.dirty == 0 then
    table.insert(lines, prop("Changes", { { "None", "SnacksPickerDimmed" } }))
    return
  end
  table.insert(lines, prop("Changes", H.badge(config.icons.file .. item.st.dirty, "SnacksGhStatBadge")))
  table.insert(lines, {})
  for i = 2, #item.status do
    local code, file = item.status[i]:sub(1, 2), item.status[i]:sub(4)
    local hl = code == "??" and "SnacksPickerDimmed"
      or code:find("D") and "SnacksGhDeletions"
      or code:find("A") and "SnacksGhAdditions"
      or "SnacksGhCheckPending"
    table.insert(lines, { { code, hl }, { " " }, { file } })
  end
end

local preview_ns = vim.api.nvim_create_namespace("user.worktrees.preview")

--- Right panel, drawn with the same components as the snacks PR view.
local function render_preview(ctx)
  local item, lines = ctx.item, {}
  pr_preview(item, lines)
  vim.list_extend(lines, { {}, { { "---", "@punctuation.special.markdown" } }, {} })
  status_preview(item, lines)
  ctx.preview:reset()
  ctx.preview:minimal()
  ctx.preview:wo({ wrap = true, linebreak = true })
  local logo = require("snacks.gh").config().icons.logo
  ctx.preview:set_title(item.pr and ("%sPR #%d"):format(logo, item.pr.number) or vim.fs.basename(item.wt.path))
  Snacks.picker.highlight.render(ctx.buf, preview_ns, lines)
end

--- Load status, PRs and agent state in the background, redrawing the panel as they arrive.
local function load_details(picker, items, main)
  local function redraw()
    if not picker.closed then
      picker.list:update({ force = true })
      picker.preview:show(picker, { force = true })
    end
  end

  local function set_prs(prs)
    for _, item in ipairs(items) do
      local pr = find_pr(prs, item.wt)
      item.pr = pr
      item.pr_state = pr and "open" or "none"
    end
  end

  for _, item in ipairs(items) do
    vim.system({ "git", "-C", item.wt.path, "status", "--porcelain", "--branch" }, { text = true }, function(res)
      vim.schedule(function()
        local lines = vim.split(res.stdout or "", "\n", { trimempty = true })
        local header = lines[1] or ""
        item.st = {
          dirty = math.max(#lines - 1, 0),
          ahead = tonumber(header:match("ahead (%d+)")),
          behind = tonumber(header:match("behind (%d+)")),
        }
        lines[1] = header:gsub("^## ", "")
        if #lines == 1 then
          table.insert(lines, "No changes")
        end
        item.status = lines
        redraw()
      end)
    end)
  end

  if pr_cache[main] then
    set_prs(pr_cache[main])
  end
  local fields = "number,title,url,headRefName,headRefOid,isDraft,isCrossRepository,reviewDecision"
  local details = "author,baseRefName,createdAt,updatedAt,labels,changedFiles,additions,deletions,"
    .. "mergeable,mergeStateStatus,statusCheckRollup"
  gh_json({ "pr", "list", "--state", "open", "--limit", "200", "--json", fields }, main, function(prs)
    if not prs then
      for _, item in ipairs(items) do
        item.pr_state = item.pr and "open" or "unavailable"
      end
      return redraw()
    end
    -- keep the checks already known, so the colors do not flicker on refresh
    local known = {}
    for _, pr in ipairs(pr_cache[main] or {}) do
      known[pr.number] = pr
    end
    for _, pr in ipairs(prs) do
      local old = known[pr.number]
      if old and old.headRefOid == pr.headRefOid then
        pr.details = old.details
      end
    end
    pr_cache[main] = prs
    set_prs(prs)
    redraw()
    -- checks are expensive, so they are only requested for the PRs on screen
    for _, item in ipairs(items) do
      local pr = item.pr
      if pr then
        gh_json({ "pr", "view", tostring(pr.number), "--json", details }, main, function(extra)
          if extra then
            pr.details = extra
            redraw()
          end
        end)
      end
    end
  end)

  local paths = vim.tbl_map(function(item)
    return item.wt.path
  end, items)
  require("user.herdr").states_async(paths, function(states)
    for _, item in ipairs(items) do
      item.agent = states[item.wt.path]
    end
    redraw()
  end)
  redraw()
end

--- Text padded (or cut) to exactly `width` cells.
local function cell(text, width, hl)
  local size = vim.fn.strdisplaywidth(text)
  if size > width then
    text = vim.fn.strcharpart(text, 0, width - 1) .. "…"
    size = width
  end
  return { text .. (" "):rep(width - size), hl }
end

--- Picker panel: <CR> open/switch, <C-n> new, <C-x> remove, <C-a> agent (herdr).
--- Opens from `git worktree list` alone; everything slower is loaded in the background.
function M.pick()
  local list = M.list()
  if not list then
    return vim.notify("Not inside a git repository", vim.log.levels.WARN)
  end
  local current = normalize(vim.fn.getcwd())
  local items = {}
  for _, wt in ipairs(list) do
    -- short location relative to the main worktree: ".", ".claude/worktrees/x", "../repo-x"
    local main = list[1].path
    local where = wt.main and "(main)"
      or (vim.startswith(wt.path, main .. "/") and wt.path:sub(#main + 2))
      or (vim.fs.dirname(wt.path) == vim.fs.dirname(main) and "../" .. vim.fs.basename(wt.path))
      or vim.fn.fnamemodify(wt.path, ":~")
    table.insert(items, {
      where = where,
      -- a detached worktree has no branch name: its folder is what identifies it
      label = wt.detached and vim.fs.basename(wt.path) or wt.branch,
      text = wt.branch .. " " .. wt.path,
      wt = wt,
      st = { dirty = 0 },
      current = wt.path == current,
      open = M.find_tab(wt.path) ~= nil,
      pr_state = "loading",
    })
  end

  -- Nerd Font glyphs: one cell wide, so the columns stay aligned
  local agent_icons = {
    working = { "󰒓", "DiagnosticInfo" },
    blocked = { "󰀨", "DiagnosticWarn" },
    done = { "󰗠", "DiagnosticOk" },
    idle = { "󰝦", "Comment" },
    unknown = { "󰋗", "Comment" },
  }
  local branch_width = 0
  for _, item in ipairs(items) do
    branch_width = math.min(math.max(branch_width, vim.fn.strdisplaywidth(item.label)), 30)
  end
  local picker = Snacks.picker.pick({
    title = "Worktrees",
    items = items,
    preview = render_preview,
    layout = { preset = "default" },
    format = function(item)
      local H, config = Snacks.picker.highlight, require("snacks.gh").config()
      local agent = agent_icons[item.agent] or { " ", "Normal" }
      local st, pr = item.st, item.pr
      local checks = pr and checks_state(pr)
      local check_hl = checks and "SnacksGhCheck" .. Snacks.picker.util.title(checks) or "Normal"
      local pr_icon = pr and vim.trim(config.icons.pr[pr.isDraft and "draft" or "open"]) or ""
      local ret = {
        { item.current and "● " or (item.open and "○ " or "  "), "Special" },
        cell(pr_icon, 2, pr and (pr.isDraft and "SnacksGhPrDraft" or "SnacksGhPrOpen") or "Normal"),
        cell(
          item.label,
          branch_width + 1,
          item.current and "Title" or (item.wt.detached and "SnacksPickerDimmed" or "Normal")
        ),
        { agent[1] .. " ", agent[2] },
        cell(pr and "#" .. pr.number or "", 8, pr and pr_highlight(pr) or "Normal"),
        cell(checks and vim.trim(config.icons.checks[checks]) or "", 2, check_hl),
      }
      -- the badge caps take 2 cells and it ends with a space
      local changes = st.dirty > 0 and config.icons.file .. st.dirty or nil
      if changes then
        H.extend(ret, H.badge(changes, "SnacksGhStatBadge"))
      end
      table.insert(ret, { (" "):rep(math.max(8 - (changes and vim.fn.strdisplaywidth(changes) + 3 or 0), 0)) })
      table.insert(ret, cell((st.ahead or 0) > 0 and "↑" .. st.ahead or "", 4, "SnacksGhAdditions"))
      table.insert(ret, cell((st.behind or 0) > 0 and "↓" .. st.behind or "", 4, "SnacksGhDeletions"))
      table.insert(ret, { item.where, "SnacksPickerDimmed" })
      return ret
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        M.open(item.wt.path)
      end
    end,
    actions = {
      wt_new = function(picker)
        picker:close()
        M.create()
      end,
      wt_remove = function(picker, item)
        picker:close()
        if item then
          M.remove(item.wt, M.pick)
        end
      end,
      wt_agent = function(picker, item)
        picker:close()
        if item then
          M.open(item.wt.path)
          require("user.herdr").focus_agent(item.wt.path)
        end
      end,
    },
    win = {
      input = {
        keys = {
          ["<c-n>"] = { "wt_new", mode = { "n", "i" }, desc = "New worktree" },
          ["<c-x>"] = { "wt_remove", mode = { "n", "i" }, desc = "Remove worktree" },
          ["<c-a>"] = { "wt_agent", mode = { "n", "i" }, desc = "Open/focus Claude (herdr)" },
        },
      },
    },
  })
  load_details(picker, items, list[1].path)
end

-- branch per cwd: the tabline redraws constantly, so git only runs on a cache miss
local branches = {}

local function branch_of(cwd)
  if branches[cwd] == nil then
    local out = vim.fn.systemlist({ "git", "-C", cwd, "branch", "--show-current" })
    branches[cwd] = vim.v.shell_error == 0 and out[1] or ""
  end
  return branches[cwd]
end

--- Tabline: one label per tab with the worktree (branch) it belongs to.
function M.tabline()
  local s = {}
  local current = vim.api.nvim_get_current_tabpage()
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local nr = vim.api.nvim_tabpage_get_number(tab)
    local label = "diff"
    local review = octo_review(tab)
    if review then
      label = "PR #" .. review.pull_request.number
    elseif not is_diff_tab(tab) then
      local cwd = vim.fn.getcwd(-1, nr)
      local head = branch_of(cwd)
      label = vim.fn.fnamemodify(cwd, ":t") .. (head ~= "" and ("  " .. head) or "")
    end
    local hl = tab == current and "%#TabLineSel#" or "%#TabLine#"
    table.insert(s, ("%s%%%dT %d %s %%T"):format(hl, nr, nr, label))
  end
  return table.concat(s) .. "%#TabLineFill#"
end

function M.setup()
  vim.o.tabline = "%!v:lua.require('user.worktrees').tabline()"
  vim.api.nvim_create_autocmd({ "DirChanged", "FocusGained", "TermClose" }, {
    group = vim.api.nvim_create_augroup("user_worktrees_tabline", { clear = true }),
    callback = function()
      branches = {}
      vim.cmd.redrawtabline()
    end,
  })
end

return M
