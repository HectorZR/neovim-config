local M = {}

local is_linux = vim.fn.has("linux") == 1
local is_mac = vim.fn.has("mac") == 1

local tools = {
  {
    name = "git",
    required = true,
    brew = "git",
    apt = "git",
    info = "Version control — required by lazy.nvim and many plugins",
  },
  {
    name = "fd",
    alias = "fdfind",
    required = true,
    brew = "fd",
    apt = "fd-find",
    info = "Fast file finder used by fzf-lua and telescope",
  },
  {
    name = "fzf",
    required = true,
    brew = "fzf",
    apt = "fzf",
    info = "Fuzzy finder — required by fzf-lua",
  },
  {
    name = "lazygit",
    required = false,
    brew = "lazygit",
    apt = "Download from https://github.com/jesseduffield/lazygit/releases",
    info = "Terminal UI for git — optional",
  },
  {
    name = "prettier",
    required = false,
    brew = "npm install -g prettier",
    apt = "npm install -g prettier",
    info = "JS/TS formatter used by conform.nvim — optional",
  },
  {
    name = "gcc",
    required = is_linux,
    brew = "xcode-select --install",
    apt = "gcc",
    info = "C compiler for tree-sitter parsers"
      .. (is_linux and " — required on Linux/WSL" or " — macOS uses Xcode CLT"),
  },
  {
    name = "rg",
    required = true,
    brew = "ripgrep",
    apt = "ripgrep",
    info = "Required by live grep, grug-far, and snacks picker",
  },
  {
    name = "node",
    required = false,
    brew = "node",
    apt = "nodejs",
    info = "Required by Copilot, LSP servers (tsserver/eslint), and prettier",
  },
  {
    name = "npm",
    required = false,
    brew = "node",
    apt = "npm",
    info = "Required to install prettier and other JS tools",
  },
}

local informational = {
  { name = "go", info = "Required by gopls LSP server" },
  { name = "opencode", info = "OpenCode CLI — required by opencode.nvim" },
}

local function install_hint(tool)
  if is_mac then
    return "brew install " .. tool.brew
  elseif is_linux then
    return "sudo apt install " .. tool.apt
  else
    return "Install " .. tool.name .. " for your OS"
  end
end

local function executable(name)
  return vim.fn.executable(name) == 1
end

function M.check()
  vim.health.start("user: external dependencies")

  for _, tool in ipairs(tools) do
    local found = executable(tool.name) or (tool.alias and executable(tool.alias))

    if found then
      vim.health.ok(tool.name .. " — " .. tool.info)
    elseif tool.required then
      vim.health.error(tool.name .. " not found. Install with: " .. install_hint(tool))
    else
      vim.health.warn(tool.name .. " not found (optional). Install with: " .. install_hint(tool))
    end
  end

  -- Linux-only: check fd symlink
  if is_linux then
    vim.health.start("user: fd symlink (Linux)")

    if executable("fd") then
      vim.health.ok("fd is directly executable")
    elseif executable("fdfind") then
      local symlink = vim.fn.expand("~/.local/bin/fd")
      if vim.fn.filereadable(symlink) == 1 or vim.fn.executable(symlink) == 1 then
        vim.health.ok("fd symlink exists at ~/.local/bin/fd")
      else
        vim.health.warn(
          "fdfind found but no fd symlink. Run: ln -sf $(which fdfind) ~/.local/bin/fd"
            .. "\n  Then ensure ~/.local/bin is in your PATH"
        )
      end
    else
      vim.health.error("fd / fdfind not found. Run: sudo apt install fd-find")
    end
  end

  -- Informational checks (go, node, npm)
  vim.health.start("user: runtime environments (informational)")

  for _, tool in ipairs(informational) do
    if executable(tool.name) then
      vim.health.ok(tool.name .. " — " .. tool.info)
    else
      vim.health.warn(tool.name .. " not found — " .. tool.info)
    end
  end
end

return M
