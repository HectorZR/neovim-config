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
      M.switch(path)
      if on_done then
        on_done(path)
      end
    end)
  end)
end

--- Go to a worktree: its herdr tab (chat and editor) inside herdr, else a tab of this nvim.
---@param focus? "agent"|"editor" pane to land on inside herdr
function M.switch(path, focus)
  local herdr = require("user.herdr")
  if herdr.available() then
    herdr.open_worktree(path, { focus = focus or "editor" })
  else
    M.open(path)
  end
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
  local close_herdr_tab = require("user.herdr").tab_closer(item.path)
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
  close_herdr_tab()
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

--- Open the PR of the current worktree in the browser. An open PR wins over older closed ones.
function M.open_pr()
  local cwd, wt = normalize(vim.fn.getcwd()), nil
  for _, item in ipairs(M.list(cwd) or {}) do
    local inside = cwd == item.path or vim.startswith(cwd, item.path .. "/")
    if inside and (not wt or #item.path > #wt.path) then
      wt = item
    end
  end
  if not wt then
    return vim.notify("Not inside a git worktree", vim.log.levels.WARN, { title = "Worktrees" })
  end
  local args = { "pr", "list", "--json", "number,url,state,headRefName,headRefOid,isCrossRepository" }
  if wt.detached then
    vim.list_extend(args, { "--state", "open", "--limit", "200" })
  else
    vim.list_extend(args, { "--state", "all", "--limit", "20", "--head", wt.branch })
  end
  gh_json(args, wt.path, function(prs)
    if not prs then
      return vim.notify("Could not read PRs (is gh logged in?)", vim.log.levels.ERROR, { title = "Worktrees" })
    end
    local open = vim.tbl_filter(function(pr)
      return pr.state == "OPEN"
    end, prs)
    local pr = find_pr(open, wt) or find_pr(prs, wt)
    if not pr then
      return vim.notify("No PR for " .. wt.branch, vim.log.levels.WARN, { title = "Worktrees" })
    end
    local _, err = vim.ui.open(pr.url)
    if err then
      return vim.notify(err, vim.log.levels.ERROR, { title = "Worktrees" })
    end
    vim.notify(("Opening PR #%d"):format(pr.number), vim.log.levels.INFO, { title = "Worktrees" })
  end)
end

--- snacks.gh settings, extended with the merge queue state it does not know about.
--- Yellow, like GitHub's queued label.
local function gh_config()
  local config = require("snacks.gh").config()
  config.icons.pr.queued = config.icons.review.pending
  vim.api.nvim_set_hl(0, "SnacksGhPrQueued", { link = "DiagnosticWarn", default = true })
  return config
end

--- `gh pr` has no merge queue field, so it comes from GraphQL. cb(true) when the PR is queued.
local function fetch_queued(pr, cwd, cb)
  local owner, repo = pr.url:match("^https?://[^/]+/([^/]+)/([^/]+)/pull/")
  if not owner then
    return cb(false)
  end
  local query = "query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo)"
    .. "{pullRequest(number:$number){isInMergeQueue}}}"
  local args = { "api", "graphql", "-f", "query=" .. query, "-f", "owner=" .. owner, "-f", "repo=" .. repo }
  vim.list_extend(args, { "-F", "number=" .. pr.number })
  gh_json(args, cwd, function(res)
    cb(vim.tbl_get(res or {}, "data", "repository", "pullRequest", "isInMergeQueue") == true)
  end)
end

local function is_queued(pr)
  return pr.details and pr.details.queued == true
end

local function pr_icon_name(pr)
  return is_queued(pr) and "queued" or pr.isDraft and "draft" or "open"
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
  if is_queued(pr) then
    return "SnacksGhPrQueued"
  elseif pr.isDraft then
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
  item.status = pr_icon_name(pr)
  return item
end

local function prop(name, value)
  local line = { { name, "SnacksGhLabel" }, { ":", "SnacksGhDelim" }, { " " } }
  Snacks.picker.highlight.extend(line, value)
  return line
end

local function pr_preview(item, lines)
  local H, config = Snacks.picker.highlight, gh_config()
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
  local H, config = Snacks.picker.highlight, gh_config()
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
  local logo = gh_config().icons.logo
  ctx.preview:set_title(item.pr and ("%sPR #%d"):format(logo, item.pr.number) or vim.fs.basename(item.wt.path))
  Snacks.picker.highlight.render(ctx.buf, preview_ns, lines)
end

--- Load status, PRs and agent state in the background, redrawing the panel as they arrive.
local prefetched = {} -- main worktree -> vim.uv.now() of the last PR refresh

--- Refresh the open PRs of a repo, and the checks of the ones that belong to `worktrees`.
--- Results land in pr_cache[main]; on_change(ok) runs each time a piece arrives.
local function fetch_prs(main, worktrees, on_change)
  prefetched[main] = vim.uv.now()
  local fields = "number,title,url,headRefName,headRefOid,isDraft,isCrossRepository,reviewDecision"
  local details = "author,baseRefName,createdAt,updatedAt,labels,changedFiles,additions,deletions,"
    .. "mergeable,mergeStateStatus,statusCheckRollup"
  gh_json({ "pr", "list", "--state", "open", "--limit", "200", "--json", fields }, main, function(prs)
    if not prs then
      return on_change(false)
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
    on_change(true)
    -- checks are expensive, so they are only requested for the PRs of these worktrees
    for _, wt in ipairs(worktrees) do
      local pr = find_pr(prs, wt)
      if pr then
        gh_json({ "pr", "view", tostring(pr.number), "--json", details }, main, function(extra)
          if extra then
            extra.queued = is_queued(pr)
            pr.details = extra
            on_change(true)
            fetch_queued(pr, main, function(queued)
              extra.queued = queued
              on_change(true)
            end)
          end
        end)
      end
    end
  end)
end

--- Load the PRs of the current repo in the background, so the panel opens with them.
--- Skipped when they were refreshed less than `max_age` ms ago.
local function prefetch_prs(max_age)
  if vim.fn.executable("gh") == 0 then
    return
  end
  local list = M.list()
  local main = list and list[1] and list[1].path
  if not main or (prefetched[main] and vim.uv.now() - prefetched[main] < max_age) then
    return
  end
  fetch_prs(main, list, function() end)
end

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
  local worktrees = vim.tbl_map(function(item)
    return item.wt
  end, items)
  fetch_prs(main, worktrees, function(ok)
    if ok then
      set_prs(pr_cache[main])
    else
      for _, item in ipairs(items) do
        item.pr_state = item.pr and "open" or "unavailable"
      end
    end
    redraw()
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

--- Text cut to `width` cells, keeping its start and end: "dependabot/go_m…/v2-2.1.1".
local function shorten(text, width)
  if vim.fn.strdisplaywidth(text) <= width then
    return text
  end
  if width < 2 then
    return ""
  end
  local tail = math.floor((width - 1) / 2)
  local head = width - 1 - tail
  return vim.fn.strcharpart(text, 0, head) .. "…" .. vim.fn.strcharpart(text, vim.fn.strchars(text) - tail)
end

--- Text cut from the start to `width` cells, where its end tells it apart: "…/help-typo".
local function shorten_start(text, width)
  if vim.fn.strdisplaywidth(text) <= width then
    return text
  end
  return width < 2 and "" or "…" .. vim.fn.strcharpart(text, vim.fn.strchars(text) - width + 1)
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

--- Picker panel: <CR> switch, <C-n> new, <C-x> remove, <C-a> switch and focus Claude.
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
  local keys = {
    ["<c-n>"] = { "wt_new", mode = { "n", "i" }, desc = "New worktree" },
    ["<c-x>"] = { "wt_remove", mode = { "n", "i" }, desc = "Remove worktree" },
    ["<c-a>"] = { "wt_agent", mode = { "n", "i" }, desc = "Open/focus Claude (herdr)" },
  }
  local picker = Snacks.picker.pick({
    title = "Worktrees",
    items = items,
    preview = render_preview,
    -- start on the worktree you are in, not on the first one
    on_show = function(picker)
      for i, item in ipairs(items) do
        if item.current then
          picker.list:set_target(i)
        end
      end
    end,
    -- wider than the default, and with more room for the list than for the preview
    layout = {
      layout = {
        box = "horizontal",
        width = 0.9,
        min_width = 120,
        height = 0.8,
        {
          box = "vertical",
          border = true,
          title = "{title} {live} {flags}",
          { win = "input", height = 1, border = "bottom" },
          { win = "list", border = "none" },
        },
        { win = "preview", title = "{preview}", border = true, width = 0.42 },
      },
    },
    -- one row per worktree: who is on it and what it is on the left, then fixed columns on the right
    -- (changes, commits ahead/behind, PR) so they line up whatever the branch name
    format = function(item)
      local H, config = Snacks.picker.highlight, gh_config()
      local agent = agent_icons[item.agent]
      local st, pr = item.st, item.pr
      local ret = {
        { item.current and "● " or (item.open and "○ " or "  "), "Special" },
        { agent and agent[1] .. " " or "  ", agent and agent[2] or nil },
      }

      -- branch and where it lives share the width the columns leave; the location gives way first
      local name_hl = item.current and "Title" or (item.wt.detached and "SnacksPickerDimmed" or nil)
      local where = item.wt.detached and item.wt.head or item.where
      table.insert(ret, {
        "",
        resolve = function(width)
          width = width - 3 -- a space before the columns, and room for the list's own margin
          local name = shorten(item.label, width)
          local room = width - vim.fn.strdisplaywidth(name) - 4 -- two spaces before it and two after
          local place = room >= 6 and shorten_start(where, room) or ""
          local used = vim.fn.strdisplaywidth(name) + (place ~= "" and 2 + vim.fn.strdisplaywidth(place) or 0)
          return {
            { name, name_hl },
            { place ~= "" and "  " .. place or "", "SnacksPickerDimmed" },
            { (" "):rep(math.max(width - used, 0) + 1) },
          }
        end,
      })

      -- uncommitted changes (the preview shows them as a badge, which would not keep the columns aligned)
      local changes = st.dirty > 0 and vim.trim(config.icons.file) .. " " .. st.dirty or ""
      table.insert(ret, cell(changes, 6, "Changed"))

      -- commits ahead of and behind the upstream
      local ahead = (st.ahead or 0) > 0 and "↑" .. st.ahead or ""
      local behind = (st.behind or 0) > 0 and "↓" .. st.behind or ""
      table.insert(ret, cell(ahead, 4, "SnacksGhAdditions"))
      table.insert(ret, cell(behind, 4, "SnacksGhDeletions"))

      -- the PR: state icon, number in the color of its status, and the checks
      if pr then
        local checks = checks_state(pr)
        local icon = pr_icon_name(pr)
        table.insert(ret, { vim.trim(config.icons.pr[icon]) .. " ", "SnacksGhPr" .. Snacks.picker.util.title(icon) })
        table.insert(ret, cell("#" .. pr.number, 7, pr_highlight(pr)))
        table.insert(
          ret,
          cell(
            checks and vim.trim(config.icons.checks[checks]) or "",
            1,
            checks and "SnacksGhCheck" .. Snacks.picker.util.title(checks) or nil
          )
        )
      else
        table.insert(ret, cell(item.pr_state == "loading" and "  …" or "", 10, "SnacksPickerDimmed"))
      end
      return ret
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        M.switch(item.wt.path)
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
          M.switch(item.wt.path, "agent")
        end
      end,
    },
    -- the same keys in the list, where snacks would otherwise select all or move down
    win = {
      input = { keys = keys },
      list = { keys = keys },
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

-- PR of the branch checked out in each working directory, for the statusline
local branch_prs = {}
local PR_REFRESH_MS = 60 * 1000
-- worktree panel PRs: reloaded in the background every 5 minutes, or on focus if older than one
local PANEL_REFRESH_MS = 5 * 60 * 1000
local PANEL_FRESH_MS = 60 * 1000

--- Icon name, label and highlight describing a PR, the most urgent state first.
--- Merged and draft use theme colors: the snacks ones are too dark on the statusline.
local function pr_summary(pr)
  if pr.state == "MERGED" then
    return "merged", "Merged", "Keyword"
  elseif pr.state == "CLOSED" then
    return "closed", "Closed", "SnacksGhPrClosed"
  elseif is_queued(pr) then
    return "queued", "Queued", "SnacksGhPrQueued"
  elseif pr.isDraft then
    return "draft", "Draft", "Comment"
  end
  local checks = checks_state(pr)
  local label = checks == "failure" and "Checks failed"
    or pr.reviewDecision == "CHANGES_REQUESTED" and "Changes requested"
    or pr.details.mergeable == "CONFLICTING" and "Conflicts"
    or checks == "pending" and "Checks running"
    or pr.reviewDecision == "APPROVED" and "Approved"
    or "Open"
  return "open", label, pr_highlight(pr)
end

local function redraw_statusline()
  local ok, lualine = pcall(require, "lualine")
  if ok then
    lualine.refresh({ place = { "statusline" } })
  end
end

local function fetch_branch_pr(cwd, entry)
  local fields = "number,url,state,isDraft,isCrossRepository,headRefName,headRefOid,reviewDecision,"
    .. "mergeable,statusCheckRollup"
  local detached = entry.ref == "HEAD"
  local wt = { branch = entry.ref, head = entry.sha:sub(1, 7), detached = detached }
  local args = { "pr", "list", "--state", "all", "--limit", "20", "--json", fields }
  vim.list_extend(args, detached and { "--search", entry.sha } or { "--head", entry.ref })
  entry.loading = true
  gh_json(args, cwd, function(prs)
    entry.loading, entry.checked = false, vim.uv.now()
    if not prs or branch_prs[cwd] ~= entry then
      return
    end
    local open = vim.tbl_filter(function(pr)
      return pr.state == "OPEN"
    end, prs)
    local pr = find_pr(open, wt) or find_pr(prs, wt)
    if pr then
      local was_queued = entry.pr and entry.pr.number == pr.number and is_queued(entry.pr)
      pr.details = { mergeable = pr.mergeable, statusCheckRollup = pr.statusCheckRollup, queued = was_queued }
    end
    entry.pr = pr
    redraw_statusline()
    if pr and pr.state == "OPEN" then
      fetch_queued(pr, cwd, function(queued)
        pr.details.queued = queued
        redraw_statusline()
      end)
    end
  end)
end

--- Update the PR of the current directory in the background. Never blocks the editor.
local function refresh_branch_pr()
  local cwd = vim.fn.getcwd()
  vim.system({ "git", "-C", cwd, "rev-parse", "HEAD", "--abbrev-ref", "HEAD" }, { text = true }, function(res)
    vim.schedule(function()
      local sha, ref = (res.stdout or ""):match("^(%x+)\n(%S+)")
      if res.code ~= 0 or not ref then
        branch_prs[cwd] = nil
        return redraw_statusline()
      end
      local entry = branch_prs[cwd]
      local moved = entry and entry.sha ~= sha
      if not entry or entry.ref ~= ref or (ref == "HEAD" and moved) then
        entry = { ref = ref, sha = sha }
        branch_prs[cwd] = entry
        redraw_statusline()
      end
      entry.sha = sha
      local fresh = entry.checked and vim.uv.now() - entry.checked < PR_REFRESH_MS
      if not entry.loading and (moved or not fresh) then
        fetch_branch_pr(cwd, entry)
      end
    end)
  end)
end

--- Statusline text for the PR of the current branch, "" when there is none.
function M.pr_status()
  local entry = branch_prs[vim.fn.getcwd()]
  if not (entry and entry.pr) then
    return ""
  end
  local icon, label = pr_summary(entry.pr)
  return ("%s #%d %s"):format(vim.trim(gh_config().icons.pr[icon]), entry.pr.number, label)
end

function M.pr_status_color()
  local entry = branch_prs[vim.fn.getcwd()]
  if entry and entry.pr then
    local _, _, hl = pr_summary(entry.pr)
    return { fg = Snacks.util.color(hl) }
  end
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

  local group = vim.api.nvim_create_augroup("user_worktrees_pr", { clear = true })
  vim.api.nvim_create_autocmd({ "DirChanged", "TabEnter", "FocusGained" }, {
    group = group,
    callback = function()
      refresh_branch_pr()
      prefetch_prs(PANEL_FRESH_MS)
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "VeryLazy",
    once = true,
    callback = function()
      refresh_branch_pr()
      -- a moment after startup, so loading the panel's PRs never competes with opening files
      vim.defer_fn(function()
        prefetch_prs(PANEL_FRESH_MS)
      end, 3000)
      local timer = assert(vim.uv.new_timer())
      timer:start(
        2 * PR_REFRESH_MS,
        2 * PR_REFRESH_MS,
        vim.schedule_wrap(function()
          refresh_branch_pr()
          prefetch_prs(PANEL_REFRESH_MS)
        end)
      )
    end,
  })
end

return M
