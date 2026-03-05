#!/usr/bin/env bash
# install-deps.sh — Bootstrap external tools for the Neovim config
# Supports macOS (Homebrew) and Debian/Ubuntu Linux (apt)
# Idempotent: skips tools that are already installed

set -euo pipefail

# ── Helpers ──────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()      { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

has() { command -v "$1" &>/dev/null; }

# ── Detect OS ─────────────────────────────────────────────────────────────────

if [[ "$(uname)" == "Darwin" ]]; then
  OS="macos"
elif [[ -f /etc/debian_version ]]; then
  OS="linux"
else
  error "Unsupported OS. This script supports macOS and Debian/Ubuntu Linux."
  exit 1
fi

# Detect WSL (runs on top of Linux)
IS_WSL=false
if [[ "$OS" == "linux" ]] && grep -qi microsoft /proc/version 2>/dev/null; then
  IS_WSL=true
fi

info "Detected OS: $OS"
$IS_WSL && info "WSL environment detected"
echo ""

# ── macOS: ensure Homebrew ────────────────────────────────────────────────────

if [[ "$OS" == "macos" ]]; then
  if ! has brew; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    ok "Homebrew already installed"
  fi
fi

# ── Linux: update apt index once ─────────────────────────────────────────────

if [[ "$OS" == "linux" ]]; then
  info "Updating apt package index..."
  sudo apt-get update -qq
fi

# ── Install functions ─────────────────────────────────────────────────────────

install_brew() {
  local pkg="$1"
  if brew list "$pkg" &>/dev/null; then
    ok "$pkg already installed (brew)"
  else
    info "Installing $pkg via brew..."
    brew install "$pkg"
  fi
}

install_apt() {
  local pkg="$1"
  if dpkg -s "$pkg" &>/dev/null 2>&1; then
    ok "$pkg already installed (apt)"
  else
    info "Installing $pkg via apt..."
    sudo apt-get install -y "$pkg"
  fi
}

# ── 1. gcc ────────────────────────────────────────────────────────────────────

echo ""
info "==> gcc (tree-sitter compiler)"

if [[ "$OS" == "macos" ]]; then
  if has gcc; then
    ok "gcc already available (Xcode CLT)"
  else
    info "Installing Xcode Command Line Tools..."
    xcode-select --install 2>/dev/null || warn "Xcode CLT install dialog opened — complete it and re-run this script"
  fi
elif [[ "$OS" == "linux" ]]; then
  install_apt gcc
fi

# ── 2. fd ─────────────────────────────────────────────────────────────────────

echo ""
info "==> fd (fast file finder)"

if [[ "$OS" == "macos" ]]; then
  if has fd; then
    ok "fd already installed"
  else
    install_brew fd
  fi
elif [[ "$OS" == "linux" ]]; then
  if has fd || has fdfind; then
    ok "fd/fdfind already installed"
  else
    install_apt fd-find
  fi

  # Create ~/.local/bin/fd symlink so plugins can call 'fd' directly
  FDFIND_PATH="$(command -v fdfind 2>/dev/null || true)"
  LOCAL_BIN="$HOME/.local/bin"
  FD_LINK="$LOCAL_BIN/fd"

  if [[ -n "$FDFIND_PATH" ]]; then
    mkdir -p "$LOCAL_BIN"
    if [[ ! -e "$FD_LINK" ]]; then
      ln -sf "$FDFIND_PATH" "$FD_LINK"
      ok "Created fd symlink: $FD_LINK -> $FDFIND_PATH"
    else
      ok "fd symlink already exists at $FD_LINK"
    fi

    # Warn if ~/.local/bin is not in PATH
    if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
      warn "~/.local/bin is not in your PATH."
      warn "Add this to your ~/.bashrc or ~/.zshrc:"
      warn '  export PATH="$HOME/.local/bin:$PATH"'
    fi
  fi
fi

# ── 3. fzf ────────────────────────────────────────────────────────────────────

echo ""
info "==> fzf (fuzzy finder)"

if [[ "$OS" == "macos" ]]; then
  if has fzf; then
    ok "fzf already installed"
  else
    install_brew fzf
  fi
elif [[ "$OS" == "linux" ]]; then
  if has fzf; then
    ok "fzf already installed"
  else
    install_apt fzf
  fi
fi

# ── 4. prettier ───────────────────────────────────────────────────────────────

echo ""
info "==> prettier (JS/TS formatter)"

if has prettier; then
  ok "prettier already installed"
elif has npm; then
  info "Installing prettier globally via npm..."
  npm install -g prettier
  ok "prettier installed"
else
  warn "npm not found — skipping prettier install."
  warn "Install Node.js/npm first, then run: npm install -g prettier"
fi

# ── 5. lazygit ────────────────────────────────────────────────────────────────

echo ""
info "==> lazygit (terminal git UI)"

if has lazygit; then
  ok "lazygit already installed"
elif [[ "$OS" == "macos" ]]; then
  install_brew lazygit
elif [[ "$OS" == "linux" ]]; then
  info "Fetching latest lazygit release from GitHub..."
  LAZYGIT_VERSION="$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
    | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')"

  if [[ -z "$LAZYGIT_VERSION" ]]; then
    warn "Could not determine latest lazygit version. Check https://github.com/jesseduffield/lazygit/releases"
  else
    ARCH="$(uname -m)"
    case "$ARCH" in
      x86_64)  ARCH_TAG="x86_64" ;;
      aarch64) ARCH_TAG="arm64"  ;;
      *)        warn "Unsupported architecture: $ARCH"; ARCH_TAG="" ;;
    esac

    if [[ -n "$ARCH_TAG" ]]; then
      TARBALL="lazygit_${LAZYGIT_VERSION}_Linux_${ARCH_TAG}.tar.gz"
      URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/${TARBALL}"

      TMP_DIR="$(mktemp -d)"
      curl -Lo "$TMP_DIR/$TARBALL" "$URL"
      tar -xf "$TMP_DIR/$TARBALL" -C "$TMP_DIR"
      sudo install "$TMP_DIR/lazygit" /usr/local/bin/lazygit
      rm -rf "$TMP_DIR"
      ok "lazygit $LAZYGIT_VERSION installed to /usr/local/bin/lazygit"
    fi
  fi
fi

# ── 6. ripgrep ────────────────────────────────────────────────────────────────

echo ""
info "==> ripgrep (fast grep for live-grep / grug-far)"

if has rg; then
  ok "ripgrep already installed"
elif [[ "$OS" == "macos" ]]; then
  install_brew ripgrep
elif [[ "$OS" == "linux" ]]; then
  install_apt ripgrep
fi

# ── 7. node / npm ─────────────────────────────────────────────────────────────

echo ""
info "==> node / npm (Copilot, LSP servers, prettier)"

if has node; then
  ok "node already installed"
elif [[ "$OS" == "macos" ]]; then
  install_brew node
elif [[ "$OS" == "linux" ]]; then
  install_apt nodejs
  install_apt npm
fi

# ── 8. imagemagick ────────────────────────────────────────────────────────────

echo ""
info "==> imagemagick (image processing for image.nvim)"

if [[ "$OS" == "macos" ]]; then
  install_brew imagemagick
elif [[ "$OS" == "linux" ]]; then
  install_apt imagemagick
fi

# ── 9. chafa ──────────────────────────────────────────────────────────────────

echo ""
info "==> chafa (image preview in fzf-lua — works in any terminal)"

if has chafa; then
  ok "chafa already installed"
elif [[ "$OS" == "macos" ]]; then
  install_brew chafa
elif [[ "$OS" == "linux" ]]; then
  install_apt chafa
fi

# ── 10. win32yank (WSL clipboard bridge) ──────────────────────────────────────

if $IS_WSL; then
  echo ""
  info "==> win32yank (WSL ↔ Windows clipboard bridge)"

  if has win32yank.exe; then
    ok "win32yank.exe already installed"
  else
    info "Downloading win32yank.exe..."
    ARCH="$(uname -m)"
    case "$ARCH" in
      x86_64)  WIN32YANK_ZIP="win32yank-x64.zip" ;;
      aarch64) WIN32YANK_ZIP="win32yank-arm64.zip" ;;
      *)        warn "Unsupported architecture: $ARCH — skipping win32yank"; WIN32YANK_ZIP="" ;;
    esac

    if [[ -n "$WIN32YANK_ZIP" ]]; then
      WIN32YANK_VERSION="$(curl -s https://api.github.com/repos/equalsraf/win32yank/releases/latest \
        | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')"
      WIN32YANK_URL="https://github.com/equalsraf/win32yank/releases/download/${WIN32YANK_VERSION}/${WIN32YANK_ZIP}"

      TMP_DIR="$(mktemp -d)"
      curl -sLo "$TMP_DIR/win32yank.zip" "$WIN32YANK_URL"
      unzip -p "$TMP_DIR/win32yank.zip" win32yank.exe > "$TMP_DIR/win32yank.exe"
      chmod +x "$TMP_DIR/win32yank.exe"
      sudo mv "$TMP_DIR/win32yank.exe" /usr/local/bin/win32yank.exe
      rm -rf "$TMP_DIR"
      ok "win32yank.exe installed to /usr/local/bin/win32yank.exe"
    fi
  fi
fi

# ── 11. claude CLI ────────────────────────────────────────────────────────────

echo ""
info "==> claude CLI (optional — for claudecode.nvim)"

if has claude; then
  ok "claude CLI found"
else
  warn "claude CLI not found. Install via: https://claude.ai/download"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "Post-install verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

MISSING=()

check_tool() {
  local name="$1"
  local alt="${2:-}"
  if has "$name" || { [[ -n "$alt" ]] && has "$alt"; }; then
    ok "$name found: $(command -v "$name" 2>/dev/null || command -v "$alt" 2>/dev/null)"
  else
    error "$name NOT found"
    MISSING+=("$name")
  fi
}

check_tool git
check_tool fd fdfind
check_tool fzf
check_tool rg
check_tool prettier
check_tool lazygit
check_tool gcc
check_tool node
check_tool npm
check_tool convert  # imagemagick
check_tool chafa
$IS_WSL && check_tool win32yank.exe

echo ""
if [[ ${#MISSING[@]} -eq 0 ]]; then
  ok "All tools installed successfully!"
else
  warn "Some tools are missing: ${MISSING[*]}"
  warn "Run ':checkhealth user' in Neovim for detailed diagnostics."
fi

echo ""
info "Open Neovim and run ':checkhealth user' to verify everything."
