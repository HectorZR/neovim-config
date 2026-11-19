-- Loads the config like an interactive session and exits with an error if anything fails.
-- Run with: nvim --headless -c "luafile .github/scripts/check-startup.lua"
local errors = {}

local notify = vim.notify
vim.notify = function(msg, level, opts)
  if level and level >= vim.log.levels.ERROR then
    table.insert(errors, tostring(msg))
  end
  return notify(msg, level, opts)
end

local function check_errmsg()
  if vim.v.errmsg ~= "" then
    table.insert(errors, vim.v.errmsg)
    vim.v.errmsg = ""
  end
end

-- once snacks takes over vim.notify, errors only land in its history
local function notifier_errors()
  local ok, history = pcall(function()
    return Snacks.notifier.get_history()
  end)
  for _, item in ipairs(ok and history or {}) do
    if item.level == "error" then
      table.insert(errors, tostring(item.msg))
    end
  end
end

local function finish()
  check_errmsg()
  notifier_errors()
  if #errors > 0 then
    local unique = {}
    for _, msg in ipairs(errors) do
      if not vim.tbl_contains(unique, msg) then
        table.insert(unique, msg)
      end
    end
    io.stderr:write("Startup errors:\n" .. table.concat(unique, "\n") .. "\n")
    vim.cmd("cquit 1")
  end
  io.stdout:write("Startup ok\n")
  vim.cmd("qall!")
end

check_errmsg()
-- headless has no UI, and lazy.nvim waits for one before loading the VeryLazy plugins
vim.api.nvim_exec_autocmds("UIEnter", {})

vim.defer_fn(function()
  local config = vim.fn.stdpath("config")
  for _, file in ipairs(vim.fn.glob(config .. "/lua/user/*.lua", false, true)) do
    local ok, err = pcall(require, "user." .. vim.fn.fnamemodify(file, ":t:r"))
    if not ok then
      table.insert(errors, err)
    end
  end
  -- the dashboard only renders when it opens, so open it like a plain `nvim` would
  local ok, err = pcall(function()
    Snacks.dashboard.open()
  end)
  if not ok then
    table.insert(errors, "dashboard: " .. tostring(err))
  end
  vim.cmd.edit(config .. "/init.lua")
  vim.cmd.colorscheme("tokyonight-moon")
  vim.defer_fn(finish, 2000)
end, 3000)
