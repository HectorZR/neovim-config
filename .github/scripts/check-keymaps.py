"""Fail when a keymap defined in lua/ has no description or is missing from the README cheatsheet."""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MODES = re.compile(r"^[nivxsot]+$")


def norm(key):
    key = key.replace("<Space>", "<leader>")
    return re.sub(r"<([^>]+)>", lambda m: "<" + m.group(1).lower() + ">", key)


def call_args(text, start):
    """String literals and the `desc` of the call whose "(" is at `start`."""
    depth, i, strings, desc = 0, start, [], None
    while i < len(text):
        ch = text[i]
        if ch == '"':
            end = text.index('"', i + 1)
            value = text[i + 1 : end]
            if depth == 1:
                strings.append(value)
            if re.search(r"desc\s*=\s*$", text[max(0, i - 12) : i]):
                desc = value
            i = end
        elif ch in "({[":
            depth += 1
        elif ch in ")}]":
            depth -= 1
            if depth == 0:
                break
        i += 1
    return strings, desc


def keymaps(text):
    # vim.keymap.set / map helpers: map("n", "<lhs>", ..., { desc }) or map("<lhs>", fn, "desc")
    for match in re.finditer(r"\b(?:vim\.keymap\.set|map)\(", text):
        if text[match.start() - 1] in ":.":
            continue  # a method such as Snacks.toggle():map(), handled below
        strings, desc = call_args(text, match.end() - 1)
        if strings and MODES.match(strings[0]):
            if len(strings) >= 2:  # otherwise the lhs is a variable, as in a local map() helper
                yield strings[1], desc
        elif strings:
            yield strings[0], desc if desc is not None else (strings[-1] if len(strings) > 1 else None)
    # lazy.nvim keys and lsp server keys: { "<lhs>", fn, desc = "..." }
    for match in re.finditer(r'\{\s*"([^"\s]+)",\s*(?=function|"<cmd>|[a-z_]+\(|[a-z_.]+,)', text):
        _, desc = call_args(text, match.start())
        if desc is not None:  # entries without desc are which-key icon specs
            yield match.group(1), desc
    # picker keys: ["<c-x>"] = { "action", desc = "..." }
    for match in re.finditer(r'\["(<[^"]+>)"\] = \{ "[a-z_]+"', text):
        _, desc = call_args(text, match.start() + match.group(0).index("{"))
        yield match.group(1), desc
    # snacks toggles: Snacks.toggle(...):map("<leader>x") take their name from the toggle
    for match in re.finditer(r'\):map\("([^"]+)"\)', text):
        yield match.group(1), "toggle"
    # codediff keymap options: open_in_prev_tab = "gf"
    for match in re.finditer(r'^\s+[a-z_]+ = "(g[a-z?])",', text, re.M):
        yield match.group(1), "codediff option"


readme = (ROOT / "README.md").read_text(encoding="utf-8")
documented = {norm(k) for line in readme.splitlines() for k in re.findall(r"`([^`]+)`", line)}

found = {}
for path in sorted((ROOT / "lua").rglob("*.lua")):
    for lhs, desc in keymaps(path.read_text(encoding="utf-8")):
        if re.match(r"^(<[^>]+>|[A-Za-z?\[\]-]{1,3})", lhs) and lhs not in found:
            found[lhs] = (path.relative_to(ROOT), desc)

problems = []
for lhs, (path, desc) in sorted(found.items()):
    if not (desc or "").strip():
        problems.append(f"{path}: {lhs} has no description, so which-key can't label it")
    if norm(lhs) not in documented:
        problems.append(f"{path}: {lhs} ({desc}) is missing from README.md")

print(f"Checked {len(found)} keymaps: {', '.join(sorted(found))}")
if problems:
    print("\n".join(problems))
    sys.exit(1)
