-- Bridge to herdr (terminal multiplexer for coding agents) through its CLI.
-- Each git worktree gets a tab running Claude Code in nvim's herdr workspace, named after the worktree.
-- Only works when nvim itself runs inside herdr (HERDR_ENV=1); otherwise text goes to the clipboard.
local M = {}

M.agent_kind = "claude"

function M.available()
  return vim.env.HERDR_ENV == "1" and vim.fn.executable("herdr") == 1
end

local function decode(out)
  local ok, res = pcall(vim.json.decode, out or "")
  return ok and type(res) == "table" and res or nil
end

--- Run a herdr command synchronously (only for fast queries).
local function run(args)
  local res = vim.system(vim.list_extend({ "herdr" }, args), { text = true }):wait(3000)
  local json = decode(res.stdout ~= "" and res.stdout or res.stderr)
  if not json or json.error then
    return nil, json and json.error and json.error.message or (res.stderr or "herdr failed")
  end
  return json.result
end

--- Run a herdr command asynchronously; cb(result, err) runs on the main loop.
local function run_async(args, cb)
  vim.system(vim.list_extend({ "herdr" }, args), { text = true }, function(res)
    local json = decode(res.stdout ~= "" and res.stdout or res.stderr)
    vim.schedule(function()
      if not json or json.error then
        cb(nil, json and json.error and (json.error.code .. ": " .. json.error.message) or res.stderr)
      else
        cb(json.result)
      end
    end)
  end)
end

--- Git worktree root of a directory, so nested worktrees (.claude/worktrees/x) stay distinct.
local function toplevel(dir)
  local out = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
  return vim.v.shell_error == 0 and out[1] or nil
end

--- Agent names must match [a-z][a-z0-9_-]{0,31} and be unique among live agents.
function M.agent_name(path, agents)
  local base = vim.fs.basename(path):lower():gsub("[^a-z0-9_-]", "-"):gsub("^[^a-z]+", "")
  base = (base == "" and "agent" or base):sub(1, 29)
  local used = {}
  for _, a in ipairs(agents or {}) do
    used[a.name or ""] = true
  end
  local name, n = base, 1
  while used[name] do
    n = n + 1
    name = base .. "-" .. n
  end
  return name
end

--- All live agents, or {} when herdr is unavailable.
function M.agents()
  if not M.available() then
    return {}
  end
  local res = run({ "agent", "list" })
  return res and res.agents or {}
end

--- Map of worktree root -> agents running in it.
local function by_worktree(agents)
  local ret, roots = {}, {}
  for _, a in ipairs(agents) do
    local cwd = a.foreground_cwd or a.cwd or ""
    if roots[cwd] == nil then
      roots[cwd] = toplevel(cwd) or false
    end
    local root = roots[cwd]
    if root then
      ret[root] = ret[root] or {}
      table.insert(ret[root], a)
    end
  end
  return ret
end

--- The agent working in the worktree containing `path`.
function M.agent_for(path, agents)
  local root = toplevel(path)
  local found = root and by_worktree(agents or M.agents())[root]
  return found and found[1] or nil
end

--- Calls cb with a map of worktree path -> agent status, without blocking the editor.
--- Status is "working" | "blocked" | "done" | "idle" | "unknown".
function M.states_async(paths, cb)
  if not M.available() then
    return
  end
  run_async({ "agent", "list" }, function(res)
    local ret = {}
    for _, agent in ipairs(res and res.agents or {}) do
      local cwd = vim.fs.normalize(agent.foreground_cwd or agent.cwd or "")
      -- the longest match, so a nested worktree is not taken for its parent
      local best
      for _, path in ipairs(paths) do
        if (cwd == path or vim.startswith(cwd, path .. "/")) and (not best or #path > #best) then
          best = path
        end
      end
      if best and not ret[best] then
        ret[best] = agent.agent_status
      end
    end
    cb(ret)
  end)
end

--- The tab left behind when this worktree's Claude exited, so it can be reused.
---@return string? pane_id
---@return string? tab_id
local function leftover_tab(path, name)
  local workspace = vim.env.HERDR_WORKSPACE_ID
  if not workspace then
    return
  end
  local tabs = run({ "tab", "list", "--workspace", workspace })
  local panes = run({ "pane", "list", "--workspace", workspace })
  for _, tab in ipairs(tabs and tabs.tabs or {}) do
    if tab.label == name and tab.pane_count == 1 and tab.tab_id ~= vim.env.HERDR_TAB_ID then
      for _, pane in ipairs(panes and panes.panes or {}) do
        if pane.tab_id == tab.tab_id and toplevel(pane.cwd or path) == path then
          return pane.pane_id, tab.tab_id
        end
      end
    end
  end
end

--- Start Claude in a tab of nvim's workspace (one per worktree). cb(agent_name) when ready.
function M.start_agent(path, opts, cb)
  opts = opts or {}
  path = toplevel(path) or path
  local name = M.agent_name(path, M.agents())

  local function launch(pane)
    vim.notify(("Starting %s in herdr tab %s…"):format(M.agent_kind, name), vim.log.levels.INFO)
    run_async({ "agent", "start", name, "--kind", M.agent_kind, "--pane", pane, "--timeout", "60000" }, function(_, e)
      if e and not e:match("^agent_not_ready") then
        return vim.notify("herdr: " .. e, vim.log.levels.ERROR)
      end
      if e then
        -- usually the folder-trust dialog on first run in a new worktree
        vim.notify(name .. " is waiting for your input in herdr (trust dialog?)", vim.log.levels.WARN)
      end
      if cb then
        cb(name, e == nil)
      end
    end)
  end

  local pane, tab = leftover_tab(path, name)
  if pane then
    if opts.focus then
      run({ "tab", "focus", tab })
    end
    return launch(pane)
  end

  local args = { "tab", "create", "--cwd", path, "--label", name, opts.focus and "--focus" or "--no-focus" }
  if vim.env.HERDR_WORKSPACE_ID then
    vim.list_extend(args, { "--workspace", vim.env.HERDR_WORKSPACE_ID })
  end
  run_async(args, function(res, err)
    if not res then
      return vim.notify("herdr: " .. tostring(err), vim.log.levels.ERROR)
    end
    launch(res.root_pane.pane_id)
  end)
end

--- Focus the worktree's agent in herdr, starting one if none exists.
function M.focus_agent(path)
  path = path or vim.fn.getcwd()
  if not M.available() then
    return vim.notify("nvim is not running inside herdr", vim.log.levels.WARN)
  end
  local agent = M.agent_for(path)
  if agent then
    run_async({ "agent", "focus", agent.name or agent.pane_id }, function(_, err)
      if err then
        vim.notify("herdr: " .. err, vim.log.levels.ERROR)
      end
    end)
  else
    M.start_agent(path, { focus = true })
  end
end

--- Keep an undelivered prompt: always in register r, and in the clipboard when there is one.
local function keep_prompt(text, reason, level)
  vim.fn.setreg("r", text)
  local copied = vim.fn.has("clipboard") == 1 and pcall(vim.fn.setreg, "+", text)
  local where = copied and "Prompt copied to the clipboard."
    or 'No clipboard available: prompt saved, paste it with "rp.'
  vim.notify(reason .. "\n" .. where, level or vim.log.levels.INFO, { title = "herdr" })
end

--- Send a prompt to the worktree's agent without leaving nvim. Falls back to the clipboard.
--- `on_sent` only runs when the agent actually received the prompt.
function M.send(path, text, on_sent)
  path = path or vim.fn.getcwd()
  if not M.available() then
    return keep_prompt(text, "nvim is not running inside herdr.")
  end
  local function prompt(target)
    run_async({ "agent", "prompt", target, text }, function(_, err)
      if err then
        keep_prompt(text, err, vim.log.levels.WARN)
      else
        vim.notify("Sent to " .. target, vim.log.levels.INFO, { title = "herdr" })
        if on_sent then
          on_sent()
        end
      end
    end)
  end
  local agent = M.agent_for(path)
  if agent then
    return prompt(agent.name or agent.pane_id)
  end
  M.start_agent(path, { focus = false }, function(name, ready)
    if ready then
      prompt(name)
    else
      keep_prompt(text, "The agent is not ready yet.", vim.log.levels.WARN)
    end
  end)
end

return M
