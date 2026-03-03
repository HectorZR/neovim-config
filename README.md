# Neovim Config Cheatsheet

Built on [LazyVim](https://lazyvim.github.io/). This file covers custom and frequently-used keymaps.
For the full LazyVim keymap reference: https://www.lazyvim.org/keymaps

---

## Setup

```sh
./install-deps.sh       # install system dependencies
```

Inside Neovim:

```
:checkhealth user       # verify all tools are healthy
:Lazy                   # plugin manager UI
:Lazy update            # update plugins + lazy-lock.json
:Mason                  # LSP / formatter / linter manager
```

---

## Leader Key

`<leader>` = **Space**

Run `:WhichKey <leader>` to interactively browse all leader bindings.

---

## Files & Navigation

| Key | Action |
|-----|--------|
| `<leader>e` | Toggle file explorer (Neo-tree) |
| `<leader>ff` | Find files |
| `<leader>fr` | Recent files |
| `<leader>fb` | Browse buffers |
| `<S-h>` / `<S-l>` | Prev / next buffer |
| `<leader>bd` | Delete buffer |
| `<leader>bb` | Switch to other buffer |

---

## Search

| Key | Action |
|-----|--------|
| `<leader>sg` | Live grep (ripgrep) |
| `<leader>sw` | Search word under cursor |
| `<leader>s"` | Search registers |
| `<leader>sk` | Search keymaps |

---

## Code (LSP)

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | References |
| `gI` | Go to implementation |
| `K` | Hover docs |
| `<leader>ca` | Code action |
| `<leader>cr` | Rename symbol |
| `<leader>cd` | Line diagnostics |
| `<leader>cf` | Format file |
| `]d` / `[d` | Next / prev diagnostic |

---

## Git

| Key | Action |
|-----|--------|
| `<leader>gg` | Open LazyGit (LazyVim default) |
| `<leader>gL` | Open LazyGit (custom binding) |
| `<leader>gb` | Git blame line |
| `<leader>gd` | Git diff |
| `]h` / `[h` | Next / prev hunk |
| `<leader>ghs` | Stage hunk |
| `<leader>ghr` | Reset hunk |

---

## AI Tools

### OpenCode (`<leader>i`)

| Key | Action |
|-----|--------|
| `<leader>ia` | Toggle OpenCode panel |
| `<leader>ii` | Ask (free text) |
| `<leader>iI` | Ask with current context |
| `<leader>ib` | Ask about buffer |
| `<leader>ipe` | Explain |
| `<leader>ipf` | Fix |
| `<leader>ipd` | Diagnose |
| `<leader>ipr` | Review |
| `<leader>ipt` | Generate tests |
| `<leader>ipo` | Optimize |

### Claude Code (`<leader>a`)

| Key | Action |
|-----|--------|
| `<leader>ac` | Toggle Claude Code |
| `<leader>as` | Send selection to Claude |

### CopilotChat (when Copilot is active)

| Key | Action |
|-----|--------|
| `<leader>aa` | Toggle CopilotChat |

Custom prompts available: Explain, Review, Tests, Refactor, Fix, Docs, Summarize.

---

## Editor

| Key | Action |
|-----|--------|
| `<leader>o` | Add empty line below |
| `<leader>O` | Add empty line above |
| `<leader>ce` | Select all |
| `<S-CR>` (insert) | New line below (stay in insert mode) |
| `<C-CR>` (insert) | New line above (stay in insert mode) |
| `<A-j>` / `<A-k>` | Move line/selection down/up (mini.move) |
| `<C-n>` | Add cursor at next match (vim-visual-multi) |

---

## Window / Splits

| Key | Action |
|-----|--------|
| `<C-h/j/k/l>` | Navigate windows |
| `<leader>w\|` | Vertical split |
| `<leader>w-` | Horizontal split |
| `<leader>wd` | Close window |
| `<leader>ww` | Other window |

---

## UI Toggles

| Key | Action |
|-----|--------|
| `<leader>uf` | Toggle format on save |
| `<leader>un` | Dismiss notifications |
| `<leader>ul` | Toggle line numbers |
| `<leader>uw` | Toggle word wrap |
| `<leader>uT` | Toggle treesitter highlight |

---

## Plugin Conditional Loading

Plugins only load when their dependency is present:

| Plugin | Requires |
|--------|----------|
| fzf-lua | `fzf` executable |
| lazygit.nvim | `lazygit` executable |
| claudecode.nvim | `claude` CLI |
| copilot.lua | `node` + Copilot auth token |
| wakatime | `~/.wakatime.cfg` with `api_key` |
| gopls LSP | `go` executable |
| opencode.nvim | not Windows |
