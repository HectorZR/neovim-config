-- Line review comments for agents.
-- Comments are stored OUTSIDE the repo, per worktree:
--   stdpath("cache")/review/<repo>-<hash>/<worktree>/comments.json
-- Files untouched for `retention_days` are deleted on startup.
-- Comments are shown as virtual lines and follow edits via extmarks.
local align = require("user.diff_align")

local M = {}

M.retention_days = 14
M.root = vim.fn.stdpath("cache") .. "/review"
local ns = vim.api.nvim_create_namespace("user_review")
local pad_ns = vim.api.nvim_create_namespace("user_review_pad")

---@class ReviewComment
---@field id integer
---@field file string path relative to the worktree
---@field lnum integer 1-based start line
---@field end_lnum integer 1-based end line
---@field code string[] snapshot of the commented lines
---@field text string
---@field created integer
---@field sent? integer
---@field resolved? boolean
---@field edited? integer

-- ── storage ──────────────────────────────────────────────────────────────────

local function git_out(args, cwd)
  local out = vim.fn.systemlist(vim.list_extend({ "git", "-C", cwd }, args))
  return vim.v.shell_error == 0 and out[1] or nil
end

--- Worktree root for a path (file or dir).
function M.worktree(path)
  local dir = vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path)
  return git_out({ "rev-parse", "--show-toplevel" }, dir)
end

local function store_path(wt)
  -- the common git dir identifies the repo across all its worktrees
  local common = git_out({ "rev-parse", "--path-format=absolute", "--git-common-dir" }, wt) or wt
  local repo = vim.fs.basename(vim.fs.dirname(common))
  local key = repo .. "-" .. vim.fn.sha256(common):sub(1, 8)
  -- hash the path too: two worktrees of a repo can share a directory name
  local name = vim.fs.basename(wt) .. "-" .. vim.fn.sha256(wt):sub(1, 8)
  return ("%s/%s/%s/comments.json"):format(M.root, key, name)
end

---@return ReviewComment[]
function M.load(wt)
  local f = io.open(store_path(wt), "r")
  if not f then
    return {}
  end
  local ok, data = pcall(vim.json.decode, f:read("*a"))
  f:close()
  return ok and type(data) == "table" and data or {}
end

function M.save(wt, comments)
  local path = store_path(wt)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local f = assert(io.open(path, "w"))
  f:write(vim.json.encode(comments))
  f:close()
end

--- Delete comment files not modified in `retention_days`, then empty dirs.
function M.cleanup()
  local limit = os.time() - M.retention_days * 86400
  for name, type in vim.fs.dir(M.root, { depth = 3 }) do
    local full = M.root .. "/" .. name
    if type == "file" then
      local st = vim.uv.fs_stat(full)
      if st and st.mtime.sec < limit then
        os.remove(full)
      end
    end
  end
  -- remove now-empty worktree and repo dirs (deepest first)
  local dirs = {}
  for name, type in vim.fs.dir(M.root, { depth = 2 }) do
    if type == "directory" then
      table.insert(dirs, M.root .. "/" .. name)
    end
  end
  table.sort(dirs, function(a, b)
    return #a > #b
  end)
  for _, d in ipairs(dirs) do
    vim.uv.fs_rmdir(d) -- fails silently if not empty
  end
end

-- ── display ──────────────────────────────────────────────────────────────────

-- buf -> { [extmark_id] = comment_id }
local marks = {}

local function buf_context(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" or vim.bo[buf].buftype ~= "" or name:match("^%a+://") then
    return nil
  end
  local wt = M.worktree(name)
  if not wt then
    return nil
  end
  return wt, name:sub(#wt + 2)
end

--- Write extmark positions back to the stored comments (lines move as files are edited).
function M.sync(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local wt = buf_context(buf)
  if not wt or not marks[buf] then
    return
  end
  local comments, changed = M.load(wt), false
  for mark_id, cid in pairs(marks[buf]) do
    local pos = vim.api.nvim_buf_get_extmark_by_id(buf, ns, mark_id, { details = true })
    for _, c in ipairs(comments) do
      if c.id == cid and pos[1] then
        local lnum, end_lnum = pos[1] + 1, (pos[3].end_row or pos[1]) + 1
        if c.lnum ~= lnum or c.end_lnum ~= end_lnum then
          c.lnum, c.end_lnum, changed = lnum, end_lnum, true
        end
      end
    end
  end
  if changed then
    M.save(wt, comments)
  end
end

--- In a codediff tab, the window showing the other side of `buf`.
local function diff_peer(buf)
  local tab = vim.api.nvim_get_current_tabpage()
  local win, others, is_diff = nil, {}, false
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    local b = vim.api.nvim_win_get_buf(w)
    local ft = vim.bo[b].filetype
    if ft:match("^codediff") or vim.api.nvim_buf_get_name(b):match("^codediff://") then
      is_diff = true
    end
    if vim.api.nvim_win_get_config(w).relative == "" and not ft:match("^codediff") then
      if b == buf then
        win = w
      else
        table.insert(others, w)
      end
    end
  end
  if is_diff and win and #others == 1 then
    return win, others[1]
  end
end

function M.render(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local wt, rel = buf_context(buf)
  if not wt then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  marks[buf] = {}
  local win, peer = diff_peer(buf)
  if peer then
    vim.api.nvim_buf_clear_namespace(vim.api.nvim_win_get_buf(peer), pad_ns, 0, -1)
  end
  local pads = {}
  local count = vim.api.nvim_buf_line_count(buf)
  for _, c in ipairs(M.load(wt)) do
    if c.file == rel and not c.resolved then
      local s, e = math.min(c.lnum, count) - 1, math.min(c.end_lnum, count) - 1
      local status = c.sent and "  (sent)" or ""
      local virt = {}
      for i, l in ipairs(vim.split(c.text, "\n")) do
        table.insert(virt, {
          { (i == 1 and " 󰆉 " or "   ") .. l, "DiagnosticVirtualTextInfo" },
          { i == 1 and status or "", "Comment" },
        })
      end
      if peer then
        -- worked out before this comment is drawn, while both sides are still in step
        table.insert(pads, align.pad(pad_ns, win, e + 1, peer, #virt))
      end
      -- range mark: gutter sign on the first line; tracked to keep line numbers in sync
      local id = vim.api.nvim_buf_set_extmark(buf, ns, s, 0, {
        end_row = e,
        sign_text = "󰆉",
        sign_hl_group = "DiagnosticInfo",
      })
      marks[buf][id] = c.id
      table.insert(pads, { text = virt, row = e })
    end
  end
  -- all positions are known: now draw the comments and their padding
  for _, p in ipairs(pads) do
    if p.text then
      vim.api.nvim_buf_set_extmark(buf, ns, p.row, 0, { virt_lines = p.text })
    else
      align.apply(p)
    end
  end
end

local function render_worktree(wt)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.startswith(vim.api.nvim_buf_get_name(buf), wt .. "/") then
      M.render(buf)
    end
  end
end

-- ── actions ──────────────────────────────────────────────────────────────────

--- Add a comment on the current line or the given range.
function M.add(line1, line2)
  local buf = vim.api.nvim_get_current_buf()
  local wt, rel = buf_context(buf)
  if not wt then
    return vim.notify("Review comments need a file inside a git worktree", vim.log.levels.WARN)
  end
  line1 = line1 or vim.fn.line(".")
  line2 = line2 or line1
  Snacks.input(
    { prompt = ("Comment %s:%d%s"):format(rel, line1, line2 ~= line1 and ("-" .. line2) or "") },
    function(text)
      if not text or vim.trim(text) == "" then
        return
      end
      M.sync(buf)
      local comments = M.load(wt)
      local max = 0
      for _, c in ipairs(comments) do
        max = math.max(max, c.id)
      end
      table.insert(comments, {
        id = max + 1,
        file = rel,
        lnum = line1,
        end_lnum = line2,
        code = vim.api.nvim_buf_get_lines(buf, line1 - 1, line2, false),
        text = text,
        created = os.time(),
      })
      M.save(wt, comments)
      M.render(buf)
    end
  )
end

--- Ids of the comments covering the cursor line.
local function ids_at_cursor(buf)
  local row = vim.fn.line(".") - 1
  local ids = {}
  for _, m in ipairs(vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })) do
    local s, e = m[2], m[4].end_row or m[2]
    if marks[buf] and marks[buf][m[1]] and row >= s and row <= e then
      ids[marks[buf][m[1]]] = true
    end
  end
  return ids
end

--- Delete the comment(s) on the cursor line.
function M.delete_at_cursor()
  local buf = vim.api.nvim_get_current_buf()
  local wt = buf_context(buf)
  if not wt then
    return
  end
  M.sync(buf)
  local ids = ids_at_cursor(buf)
  if vim.tbl_isempty(ids) then
    return vim.notify("No review comment on this line", vim.log.levels.INFO)
  end
  M.save(
    wt,
    vim.tbl_filter(function(c)
      return not ids[c.id]
    end, M.load(wt))
  )
  M.render(buf)
end

--- Change the text of comment `id`. An edited comment counts as not sent, so the next send includes it.
local function edit(wt, id, done)
  local comment
  for _, c in ipairs(M.load(wt)) do
    if c.id == id then
      comment = c
    end
  end
  if not comment then
    return
  end
  local loc = comment.lnum == comment.end_lnum and ("%s:%d"):format(comment.file, comment.lnum)
    or ("%s:%d-%d"):format(comment.file, comment.lnum, comment.end_lnum)
  Snacks.input({ prompt = "Edit comment " .. loc, default = comment.text }, function(text)
    if text and vim.trim(text) ~= "" and text ~= comment.text then
      -- reload: the file may have changed while the input was open
      local comments = M.load(wt)
      for _, c in ipairs(comments) do
        if c.id == id then
          c.text, c.edited, c.sent = text, os.time(), nil
        end
      end
      M.save(wt, comments)
      render_worktree(wt)
    end
    if done then
      done()
    end
  end)
end

--- Edit the comment on the cursor line; asks which one when several cover it.
function M.edit_at_cursor()
  local buf = vim.api.nvim_get_current_buf()
  local wt = buf_context(buf)
  if not wt then
    return
  end
  M.sync(buf)
  local ids = ids_at_cursor(buf)
  local found = vim.tbl_filter(function(c)
    return ids[c.id]
  end, M.load(wt))
  if #found == 0 then
    return vim.notify("No review comment on this line", vim.log.levels.INFO)
  elseif #found == 1 then
    return edit(wt, found[1].id)
  end
  vim.ui.select(found, {
    prompt = "Edit which comment?",
    format_item = function(c)
      return (c.text:gsub("\n", " "))
    end,
  }, function(c)
    if c then
      edit(wt, c.id)
    end
  end)
end

--- Markdown prompt for the agent from a list of comments.
function M.format(comments)
  local out = {
    "Code review comments on this worktree. Address each one, then summarize what you changed per comment number.",
    "Line numbers are where the comment was made; if the code moved, locate it by the quoted snippet.",
    "",
  }
  for _, c in ipairs(comments) do
    local loc = c.lnum == c.end_lnum and ("%s:%d"):format(c.file, c.lnum)
      or ("%s:%d-%d"):format(c.file, c.lnum, c.end_lnum)
    table.insert(out, ("## %d. %s"):format(c.id, loc))
    table.insert(out, c.text)
    if c.code and #c.code > 0 then
      local ft = vim.filetype.match({ filename = c.file }) or ""
      table.insert(out, "```" .. ft)
      vim.list_extend(out, c.code)
      table.insert(out, "```")
    end
    table.insert(out, "")
  end
  return table.concat(out, "\n")
end

--- Send all pending (unsent, unresolved) comments of the current worktree to its agent.
function M.send(opts)
  opts = opts or {}
  local octo = package.loaded["user.octo_inline"]
  if octo and octo.active() then
    return octo.send(opts)
  end
  local wt = M.worktree(vim.fn.expand("%:p") ~= "" and vim.fn.expand("%:p") or vim.fn.getcwd())
  if not wt then
    return vim.notify("Not inside a git worktree", vim.log.levels.WARN)
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      M.sync(buf)
    end
  end
  local comments = M.load(wt)
  local pending = vim.tbl_filter(function(c)
    return not c.resolved and (opts.all or not c.sent)
  end, comments)
  if #pending == 0 then
    return vim.notify("No pending review comments", vim.log.levels.INFO)
  end
  local ids = {}
  for _, c in ipairs(pending) do
    ids[c.id] = true
  end
  require("user.herdr").send(wt, M.format(pending), function()
    -- reload: comments may have changed while the prompt was being delivered
    local now, current = os.time(), M.load(wt)
    for _, c in ipairs(current) do
      if ids[c.id] then
        c.sent = now
      end
    end
    M.save(wt, current)
    render_worktree(wt)
  end)
end

--- Ask the agent about the current selection/line right away (no stored comment).
function M.ask(line1, line2)
  local octo = package.loaded["user.octo_inline"]
  if octo and octo.active() then
    return octo.ask(line1, line2)
  end
  local buf = vim.api.nvim_get_current_buf()
  local wt, rel = buf_context(buf)
  if not wt then
    return vim.notify("Need a file inside a git worktree", vim.log.levels.WARN)
  end
  line1 = line1 or vim.fn.line(".")
  line2 = line2 or line1
  Snacks.input({ prompt = ("Ask agent about %s:%d-%d"):format(rel, line1, line2) }, function(text)
    if not text or vim.trim(text) == "" then
      return
    end
    local ft = vim.bo[buf].filetype
    local code = vim.api.nvim_buf_get_lines(buf, line1 - 1, line2, false)
    local prompt = ("%s\n\n`%s:%d-%d`\n```%s\n%s\n```"):format(text, rel, line1, line2, ft, table.concat(code, "\n"))
    require("user.herdr").send(wt, prompt)
  end)
end

--- Picker with every comment of the current worktree.
function M.pick()
  local wt = M.worktree(vim.fn.getcwd())
  if not wt then
    return vim.notify("Not inside a git worktree", vim.log.levels.WARN)
  end
  local items = {}
  for _, c in ipairs(M.load(wt)) do
    table.insert(items, {
      text = c.text .. " " .. vim.fs.basename(c.file),
      file = wt .. "/" .. c.file,
      pos = { c.lnum, 0 },
      end_pos = { c.end_lnum, 0 },
      comment = c,
    })
  end
  table.sort(items, function(a, b)
    if (a.comment.resolved or false) ~= (b.comment.resolved or false) then
      return not a.comment.resolved
    end
    return a.comment.id < b.comment.id
  end)
  local function update(item, fn)
    local comments = M.load(wt)
    comments = fn(comments, item.comment.id)
    M.save(wt, comments)
    render_worktree(wt)
  end
  local keys = {
    ["<c-r>"] = { "review_resolve", mode = { "n", "i" }, desc = "Toggle resolved" },
    ["<c-x>"] = { "review_delete", mode = { "n", "i" }, desc = "Delete comment" },
    ["<c-e>"] = { "review_edit", mode = { "n", "i" }, desc = "Edit comment" },
  }
  Snacks.picker.pick({
    title = "Review comments",
    items = items,
    format = function(item)
      local c = item.comment
      local state = c.resolved and { "✓ ", "DiagnosticOk" }
        or (c.sent and { "➜ ", "DiagnosticHint" } or { "● ", "DiagnosticInfo" })
      return {
        state,
        { (c.text:gsub("\n", " ")) .. " ", c.resolved and "Comment" or "Normal" },
        { ("%s:%d"):format(vim.fs.basename(c.file), c.lnum), "Directory" },
      }
    end,
    actions = {
      review_resolve = function(picker, item)
        update(item, function(cs, id)
          for _, c in ipairs(cs) do
            if c.id == id then
              c.resolved = not c.resolved
            end
          end
          return cs
        end)
        picker:close()
        M.pick()
      end,
      review_edit = function(picker, item)
        if item then
          picker:close()
          -- once the picker is gone: closing it leaves insert mode, which would land in the input
          vim.schedule(function()
            edit(wt, item.comment.id, M.pick)
          end)
        end
      end,
      review_delete = function(picker, item)
        update(item, function(cs, id)
          return vim.tbl_filter(function(c)
            return c.id ~= id
          end, cs)
        end)
        picker:close()
        M.pick()
      end,
    },
    -- the same keys in the list, so they work wherever the cursor is
    win = {
      input = { keys = keys },
      list = { keys = keys },
    },
  })
end

function M.setup()
  local group = vim.api.nvim_create_augroup("user_review", { clear = true })
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    callback = function(ev)
      M.render(ev.buf)
    end,
  })
  vim.api.nvim_create_autocmd({ "BufWritePost", "BufLeave" }, {
    group = group,
    callback = function(ev)
      if marks[ev.buf] and next(marks[ev.buf]) then
        M.sync(ev.buf)
      end
    end,
  })
  -- codediff fills its windows asynchronously: align once the content is there
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "CodeDiffOpen", "CodeDiffFileSelect", "CodeDiffVirtualFileLoaded" },
    callback = function()
      vim.defer_fn(function()
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          M.render(vim.api.nvim_win_get_buf(win))
        end
      end, 150)
    end,
  })
  vim.defer_fn(M.cleanup, 2000)
end

return M
