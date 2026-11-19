# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Neovim 0.12+ configuration built on [LazyVim](https://lazyvim.github.io/), tuned for reviewing agent-written code and writing prose. LazyVim provides sensible defaults; this repo customizes and extends those defaults, and disables the plugins it does not use (`lua/plugins/disabled.lua`).

## Architecture

- `init.lua` — entry point; bootstraps lazy.nvim and loads `config.lazy`
- `lua/config/lazy.lua` — sets up lazy.nvim, imports LazyVim defaults, then imports `lua/plugins/`
- `lua/config/keymaps.lua` — custom keymaps layered on top of LazyVim defaults
- `lua/config/options.lua` — custom options layered on top of LazyVim defaults
- `lua/config/autocmds.lua` — custom autocommands layered on top of LazyVim defaults
- `lua/plugins/` — each file returns a plugin spec table; auto-imported by lazy.nvim
- `lua/user/worktrees.lua` — one tab per git worktree, snacks picker panel, tabline
- `lua/user/review.lua` — line review comments, stored in `stdpath("cache")/review`, 14-day retention
- `lua/user/herdr.lua` — herdr CLI bridge: one tab per worktree with Claude and nvim side by side
- `lua/user/review_panel.lua` — commits panel next to the codediff file list
- `lua/user/octo_inline.lua` — inline PR comments in octo reviews and sending them to Claude; wraps octo internals
- `lua/user/diff_align.lua` — keeps side-by-side diffs aligned when virtual lines are added
- `lua/user/theme.lua` — diff colors derived from the active colorscheme
- `lua/user/focus.lua` — line numbers and current line only in the active window
- `lua/user/dashboard.lua` — dashboard panel with the HZ logo, a greeting and the current repository

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
- **Picker**: `snacks.picker` only
- **Review**: `codediff.nvim` for local changes and `octo.nvim` for GitHub PR comments, under `<leader>r`
- **Agent**: Claude Code through herdr under `<leader>a`; OpenCode under `<leader>i`
- **Writing**: `render-markdown.nvim`, Spanish + English spelling, `ltex_plus` grammar checks
- **Dashboard**: HZ logo and live greeting panel via `snacks.nvim`

## Keymaps

`README.md` is the keymap cheatsheet. Update it whenever a keymap is added, changed or removed, and give every
keymap a `desc` so it shows up in which-key.

## Supported systems

macOS is the main system; Debian/Ubuntu Linux is used for testing. `install-deps.sh` covers both. Windows and WSL are not supported.

Treesitter compiles parsers natively and requires a C compiler (`gcc`, or the Xcode Command Line Tools on macOS).

## lazy-lock.json

This file pins exact plugin commit SHAs. Update it by running `:Lazy update` inside Neovim. Commit it to reproduce a known-good plugin state.
