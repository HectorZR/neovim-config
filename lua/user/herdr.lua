-- Bridge to herdr (terminal multiplexer for coding agents) through its CLI.
-- Each git worktree gets a tab in nvim's herdr workspace: Claude Code on the left, nvim on the right.
-- Only works when nvim itself runs inside herdr (HERDR_ENV=1); otherwise text goes to the clipboard.
local M = {}

M.agent_kind = "claude"

-- share of the tab width used by the chat
local CHAT_RATIO = "0.42"

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

--- Valid agent name for a path: [a-z][a-z0-9_-]{0,28}. Also the label of the worktree's tab.
local function base_name(path)
  local base = vim.fs.basename(path):lower():gsub("[^a-z0-9_-]", "-"):gsub("^[^a-z]+", "")
  return (base == "" and "agent" or base):sub(1, 29)
end

--- Agent names must be unique among live agents.
function M.agent_name(path, agents)
  local base = base_name(path)
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

local function notify_error(err)
  vim.notify("herdr: " .. tostring(err), vim.log.levels.ERROR)
end

--- New panes must start with the same nvim config as this one.
local function env_args()
  return vim.env.NVIM_APPNAME and { "--env", "NVIM_APPNAME=" .. vim.env.NVIM_APPNAME } or {}
end

local function own_worktree(path)
  return vim.env.HERDR_PANE_ID and path == toplevel(vim.fn.getcwd())
end

--- The worktree's tab in this workspace and its panes.
local function find_tab(path)
  local workspace = vim.env.HERDR_WORKSPACE_ID
  if not workspace then
    return
  end
  local label = base_name(path)
  local tabs = run({ "tab", "list", "--workspace", workspace })
  local panes = run({ "pane", "list", "--workspace", workspace })
  for _, tab in ipairs(tabs and tabs.tabs or {}) do
    if tab.label == label and tab.tab_id ~= vim.env.HERDR_TAB_ID then
      local found = vim.tbl_filter(function(pane)
        return pane.tab_id == tab.tab_id and toplevel(pane.cwd or path) == path
      end, panes and panes.panes or {})
      if #found > 0 then
        return tab, found
      end
    end
  end
end

--- A pane sitting at its shell prompt, with nothing running in it.
local function is_idle(pane_id)
  local res = run({ "pane", "process-info", "--pane", pane_id })
  local info = res and res.process_info
  local process = info and info.foreground_processes and info.foreground_processes[1]
  return process ~= nil and process.pid == info.shell_pid
end

local function idle_pane(panes)
  for _, pane in ipairs(panes) do
    if pane.pane_id ~= vim.env.HERDR_PANE_ID and is_idle(pane.pane_id) then
      return pane.pane_id
    end
  end
end

local function launch_agent(name, pane, cb)
  vim.notify(("Starting %s in herdr tab %s…"):format(M.agent_kind, name), vim.log.levels.INFO)
  run_async({ "agent", "start", name, "--kind", M.agent_kind, "--pane", pane, "--timeout", "60000" }, function(_, e)
    if e and not e:match("^agent_not_ready") then
      return notify_error(e)
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

--- Start nvim in a new pane, once its shell has printed the prompt.
local function launch_editor(pane)
  run_async({ "pane", "wait-output", pane, "--regex", "\\S", "--source", "visible", "--timeout", "5000" }, function()
    run_async({ "pane", "run", pane, vim.fn.shellescape(vim.v.progpath) }, function(_, err)
      if err then
        notify_error(err)
      end
    end)
  end)
end

local function split_args(pane, path, focus)
  local args = { "pane", "split", pane, "--direction", "right", "--ratio", CHAT_RATIO, "--cwd", path }
  vim.list_extend(args, env_args())
  table.insert(args, focus and "--focus" or "--no-focus")
  return args
end

--- Move the focus from the editor to the chat on its left.
local function focus_chat(editor)
  run_async({ "pane", "focus", "--pane", editor, "--direction", "left" }, function() end)
end

--- Add the editor to the right of the chat pane.
local function add_editor(chat, path, focus)
  run_async(split_args(chat, path, focus), function(res, err)
    if not res then
      return notify_error(err)
    end
    launch_editor(res.pane.pane_id)
  end)
end

--- Add a chat to the left of the editor pane.
local function add_chat(editor, path, name, focus, cb)
  run_async(split_args(editor, path, false), function(res, err)
    if not res then
      return notify_error(err)
    end
    local chat = res.pane.pane_id
    -- swapping moves the focus to the chat
    run_async({ "pane", "swap", "--source-pane", chat, "--target-pane", editor }, function(_, swap_err)
      if swap_err then
        return notify_error(swap_err)
      end
      if not focus then
        run_async({ "pane", "focus", "--pane", chat, "--direction", "right" }, function() end)
      end
      launch_agent(name, chat, cb)
    end)
  end)
end

--- Open the worktree's tab, creating chat and editor as needed.
--- focus: "agent" | "editor" | false (stay here).
function M.open_worktree(path, opts, cb)
  opts = opts or {}
  path = toplevel(path) or path
  local focus = opts.focus
  if own_worktree(path) then
    return focus == "agent" and M.focus_agent(path) or nil
  end
  local agents = M.agents()
  local agent = M.agent_for(path, agents)
  local name = M.agent_name(path, agents)
  local tab, panes = find_tab(path)
  if not tab then
    if agent then
      -- started before this layout existed, somewhere else
      return focus and M.focus_agent(path) or nil
    end
    local args = { "tab", "create", "--cwd", path, "--label", base_name(path) }
    vim.list_extend(args, env_args())
    vim.list_extend(args, { focus and "--focus" or "--no-focus" })
    if vim.env.HERDR_WORKSPACE_ID then
      vim.list_extend(args, { "--workspace", vim.env.HERDR_WORKSPACE_ID })
    end
    return run_async(args, function(res, err)
      if not res then
        return notify_error(err)
      end
      local chat = res.root_pane.pane_id
      add_editor(chat, path, focus == "editor")
      launch_agent(name, chat, cb)
    end)
  end

  if focus then
    run({ "tab", "focus", tab.tab_id })
  end
  if agent then
    if #panes == 1 then
      add_editor(panes[1].pane_id, path, focus == "editor")
    elseif focus == "agent" then
      M.focus_agent(path)
    end
    return cb and cb(agent.name or agent.pane_id, true)
  end
  local idle = idle_pane(panes)
  if idle then
    if #panes == 1 then
      add_editor(idle, path, focus == "editor")
    elseif focus == "agent" then
      for _, pane in ipairs(panes) do
        if pane.pane_id ~= idle then
          focus_chat(pane.pane_id)
          break
        end
      end
    end
    return launch_agent(name, idle, cb)
  end
  add_chat(panes[1].pane_id, path, name, focus == "agent", cb)
end

--- Start Claude for the worktree: next to this nvim, or in the worktree's own tab.
function M.start_agent(path, opts, cb)
  opts = opts or {}
  path = toplevel(path) or path
  if not own_worktree(path) then
    return M.open_worktree(path, { focus = opts.focus and "agent" or false }, cb)
  end
  local name = M.agent_name(path, M.agents())
  local res = run({ "pane", "list", "--workspace", vim.env.HERDR_WORKSPACE_ID })
  local panes = vim.tbl_filter(function(pane)
    return pane.tab_id == vim.env.HERDR_TAB_ID
  end, res and res.panes or {})
  local idle = idle_pane(panes)
  if idle then
    if opts.focus then
      focus_chat(vim.env.HERDR_PANE_ID)
    end
    return launch_agent(name, idle, cb)
  end
  add_chat(vim.env.HERDR_PANE_ID, path, name, opts.focus, cb)
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
        notify_error(err)
      end
    end)
  else
    M.start_agent(path, { focus = true })
  end
end

--- Give this nvim the whole tab, or bring the chat back.
function M.toggle_chat()
  if not (M.available() and vim.env.HERDR_PANE_ID) then
    return vim.notify("nvim is not running inside herdr", vim.log.levels.WARN)
  end
  run_async({ "pane", "zoom", "--pane", vim.env.HERDR_PANE_ID }, function(_, err)
    if err then
      notify_error(err)
    end
  end)
end

--- Find the worktree's tab now and return a function that closes it. For use before removing
--- the worktree, when its path can still be resolved.
function M.tab_closer(path)
  local tab = M.available() and find_tab(toplevel(path) or path) or nil
  return function()
    if tab then
      run_async({ "tab", "close", tab.tab_id }, function() end)
    end
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
