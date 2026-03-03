# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Neovim configuration built on [LazyVim](https://lazyvim.github.io/). LazyVim provides sensible defaults; this repo customizes and extends those defaults.

## Architecture

- `init.lua` — entry point; bootstraps lazy.nvim and loads `config.lazy`
- `lua/config/lazy.lua` — sets up lazy.nvim, imports LazyVim defaults, then imports `lua/plugins/`
- `lua/config/keymaps.lua` — custom keymaps layered on top of LazyVim defaults
- `lua/config/options.lua` — custom options layered on top of LazyVim defaults
- `lua/config/autocmds.lua` — custom autocommands layered on top of LazyVim defaults
- `lua/plugins/` — each file returns a plugin spec table; auto-imported by lazy.nvim

## Plugin Customization Pattern

Every file in `lua/plugins/` returns a lazy.nvim spec. To override a LazyVim plugin, match it by name and merge with `opts`:

```lua
return {
  "plugin/name",
  opts = function(_, opts)
    -- merge into existing opts
    opts.some_key = "value"
  end,
}
```

To add a new plugin from scratch:

```lua
return {
  {
    "author/plugin",
    event = "VeryLazy",  -- lazy load trigger
    opts = {},
  },
}
```

## Formatting

Lua files use [StyLua](https://github.com/JohnnyMorganz/StyLua) with 2-space indentation and 120-column width (see `stylua.toml`). Format with:

```sh
stylua lua/
```

## Key Customizations

- **Colorscheme**: `catppuccin-frappe` (set in `plugins/colorscheme.lua`)
- **Formatter**: `conform.nvim` runs `prettier` for JS/TS/JSX/TSX files
- **AI**: GitHub Copilot (`copilot.lua`) + CopilotChat with custom prompts
- **Editor extras**: `mini.move` (move lines/selections), `vim-visual-multi` (multi-cursor)
- **Statusline**: lualine with `lualine_y` cleared, `lualine_z` showing progress + location
- **Dashboard**: custom ASCII header via `snacks.nvim`

## WSL

Treesitter compiles parsers natively and requires `gcc`. Without it, syntax highlighting and noice.nvim command-line highlighting silently fail.

```bash
sudo apt install gcc
```

After installing, run `:TSInstall javascript typescript tsx regex vim` inside Neovim.

## lazy-lock.json

This file pins exact plugin commit SHAs. Update it by running `:Lazy update` inside Neovim. Commit it to reproduce a known-good plugin state.
