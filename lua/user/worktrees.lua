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

--- Tab number whose tab-local cwd is `path`, ignoring special tabs (diffs etc).
function M.find_tab(path)
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local nr = vim.api.nvim_tabpage_get_number(tab)
    local win = vim.api.nvim_tabpage_get_win(tab)
    local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
    if not ft:match("^codediff") and normalize(vim.fn.getcwd(-1, nr)) == path then
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
  local tab = M.find_tab(item.path)
  if tab and #vim.api.nvim_list_tabpages() > 1 then
    vim.cmd.tabclose(vim.api.nvim_tabpage_get_number(tab))
  end
  local args = { "worktree", "remove", item.path }
  if st.dirty > 0 then
    table.insert(args, "--force")
  end
  local out = vim.fn.system(vim.list_extend({ "git", "-C", main_path() or vim.fn.getcwd() }, args))
  if vim.v.shell_error ~= 0 then
    return vim.notify(out, vim.log.levels.ERROR, { title = "git worktree remove" })
  end
  vim.notify("Removed " .. item.path, vim.log.levels.INFO, { title = "Worktrees" })
  if on_done then
    on_done()
  end
end

--- Picker panel: <CR> open/switch, <C-n> new, <C-x> remove, <C-a> agent (herdr).
function M.pick()
  local list = M.list()
  if not list then
    return vim.notify("Not inside a git repository", vim.log.levels.WARN)
  end
  local current = normalize(vim.fn.getcwd())
  local items = {}
  for _, wt in ipairs(list) do
    local st = M.status(wt.path)
    local agent = package.loaded["user.herdr"] and require("user.herdr").agent_state(wt.path) or nil
    local log = git({ "log", "--oneline", "--decorate", "-15" }, wt.path) or {}
    local changes = git({ "status", "--short" }, wt.path) or {}
    local lines = { "# " .. wt.path, "", "## Changes (" .. #changes .. ")" }
    vim.list_extend(lines, changes)
    vim.list_extend(lines, { "", "## Log" })
    vim.list_extend(lines, log)
    -- short location relative to the main worktree: ".", ".claude/worktrees/x", "../repo-x"
    local main = list[1].path
    local where = wt.main and "(main)"
      or (vim.startswith(wt.path, main .. "/") and wt.path:sub(#main + 2))
      or (vim.fs.dirname(wt.path) == vim.fs.dirname(main) and "../" .. vim.fs.basename(wt.path))
      or vim.fn.fnamemodify(wt.path, ":~")
    table.insert(items, {
      where = where,
      text = wt.branch .. " " .. wt.path,
      wt = wt,
      st = st,
      agent = agent,
      current = wt.path == current,
      open = M.find_tab(wt.path) ~= nil,
      preview = { text = table.concat(lines, "\n"), ft = "markdown" },
    })
  end

  local agent_icons = { working = "⚙ ", blocked = "✋", done = "✅", idle = "· " }
  Snacks.picker.pick({
    title = "Worktrees",
    items = items,
    preview = "preview",
    layout = { preset = "default" },
    format = function(item)
      local ret = {}
      table.insert(ret, { item.current and "● " or (item.open and "○ " or "  "), "Special" })
      table.insert(ret, { ("%-32s"):format(item.wt.branch), item.current and "Title" or "Normal" })
      if item.agent then
        table.insert(ret, { (agent_icons[item.agent] or "  ") .. " ", "DiagnosticInfo" })
      end
      if item.st.dirty > 0 then
        table.insert(ret, { ("~%d "):format(item.st.dirty), "DiagnosticWarn" })
      end
      if (item.st.ahead or 0) > 0 then
        table.insert(ret, { ("↑%d "):format(item.st.ahead), "DiagnosticOk" })
      end
      if (item.st.behind or 0) > 0 then
        table.insert(ret, { ("↓%d "):format(item.st.behind), "DiagnosticError" })
      end
      table.insert(ret, { item.where, "Comment" })
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
end

--- Tabline: one label per tab with the worktree (branch) it belongs to.
function M.tabline()
  local s = {}
  for nr = 1, vim.fn.tabpagenr("$") do
    local cwd = vim.fn.getcwd(-1, nr)
    local win = vim.fn.tabpagewinnr(nr)
    local buf = vim.fn.tabpagebuflist(nr)[win]
    local ft = vim.bo[buf].filetype
    local label
    if ft:match("^codediff") then
      label = " diff"
    else
      local head = vim.fn.systemlist({ "git", "-C", cwd, "branch", "--show-current" })[1]
      label = vim.fn.fnamemodify(cwd, ":t") .. ((vim.v.shell_error == 0 and head and head ~= "") and ("  " .. head) or "")
    end
    local hl = nr == vim.fn.tabpagenr() and "%#TabLineSel#" or "%#TabLine#"
    table.insert(s, ("%s%%%dT %d %s %%T"):format(hl, nr, nr, label))
  end
  return table.concat(s) .. "%#TabLineFill#"
end

-- branch lookups shell out, so cache the rendered tabline and refresh on relevant events
local cached
function M.render_tabline()
  return cached or M.tabline()
end

function M.setup()
  vim.o.tabline = "%!v:lua.require('user.worktrees').render_tabline()"
  vim.api.nvim_create_autocmd({ "TabEnter", "TabNew", "TabClosed", "DirChanged", "FocusGained", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("user_worktrees_tabline", { clear = true }),
    callback = function()
      cached = nil
      cached = M.tabline()
      vim.cmd.redrawtabline()
    end,
  })
end

return M
