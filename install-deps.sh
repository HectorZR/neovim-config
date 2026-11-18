#!/usr/bin/env bash
# install-deps.sh — Install the external tools this Neovim config needs.
# Supports macOS (Homebrew) and Debian/Ubuntu Linux (apt + ~/.local).
# Safe to re-run: anything already installed is skipped.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
has() { command -v "$1" &>/dev/null; }

NVIM_MIN_MINOR=12
LOCAL_BIN="$HOME/.local/bin"
LOCAL_OPT="$HOME/.local/opt"

nvim_is_current() {
  has nvim || return 1
  local version
  version="$(nvim --version | sed -n 1p)"
  [[ "$version" =~ v([0-9]+)\.([0-9]+) ]] || return 1
  ((BASH_REMATCH[1] > 0 || BASH_REMATCH[2] >= NVIM_MIN_MINOR))
}

# ── macOS ─────────────────────────────────────────────────────────────────────

install_macos() {
  if ! has brew; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # A fresh Homebrew is not on PATH yet
  if ! has brew; then
    for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      [[ -x "$candidate" ]] && eval "$("$candidate" shellenv)" && break
    done
  fi

  if ! has gcc; then
    info "Installing Xcode Command Line Tools..."
    xcode-select --install 2>/dev/null || true
    warn "Finish the Xcode Command Line Tools dialog, then re-run this script"
  fi

  if nvim_is_current; then
    ok "Neovim is up to date"
  elif brew list neovim &>/dev/null; then
    info "Upgrading Neovim..."
    brew upgrade neovim
  else
    info "Installing Neovim..."
    brew install neovim
  fi

  local entry tool formula
  for entry in fd:fd rg:ripgrep node:node lazygit:lazygit herdr:herdr magick:imagemagick; do
    tool="${entry%%:*}"
    formula="${entry##*:}"
    if has "$tool"; then
      ok "$tool already installed"
    else
      info "Installing $formula..."
      brew install "$formula" || warn "Could not install $formula"
    fi
  done
}

# ── Linux ─────────────────────────────────────────────────────────────────────

# download <url> <destination>: the destination only appears if the download succeeds
download() {
  curl -fsSL -o "$2.part" "$1" && mv "$2.part" "$2"
}

install_apt_packages() {
  local missing=() pkg
  for pkg in git curl gcc unzip fd-find ripgrep nodejs npm; do
    dpkg -s "$pkg" &>/dev/null || missing+=("$pkg")
  done
  if [[ ${#missing[@]} -eq 0 ]]; then
    ok "apt packages already installed"
    return
  fi
  info "Installing via apt: ${missing[*]}"
  sudo apt-get update -qq
  sudo apt-get install -y "${missing[@]}"
}

install_nvim_linux() {
  if nvim_is_current; then
    ok "Neovim is up to date"
    return
  fi
  local name="nvim-linux-$NVIM_ARCH" tmp
  info "Installing the latest Neovim to $LOCAL_OPT/$name..."
  tmp="$(mktemp -d)"
  download "https://github.com/neovim/neovim/releases/latest/download/$name.tar.gz" "$tmp/nvim.tar.gz"
  tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"
  rm -rf "${LOCAL_OPT:?}/$name"
  mv "$tmp/$name" "$LOCAL_OPT/$name"
  ln -sfn "$LOCAL_OPT/$name/bin/nvim" "$LOCAL_BIN/nvim"
  rm -rf "$tmp"
}

install_lazygit_linux() {
  if has lazygit; then
    ok "lazygit already installed"
    return
  fi
  info "Installing lazygit to $LOCAL_BIN..."
  local latest version tmp
  latest="$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/jesseduffield/lazygit/releases/latest)" || latest=""
  version="${latest##*/v}"
  if [[ -z "$version" || "$version" == "$latest" ]]; then
    warn "Could not determine the latest lazygit version"
    return
  fi
  tmp="$(mktemp -d)"
  if download "https://github.com/jesseduffield/lazygit/releases/download/v$version/lazygit_${version}_linux_$LAZYGIT_ARCH.tar.gz" "$tmp/lazygit.tar.gz" &&
    tar -xzf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit; then
    install -m755 "$tmp/lazygit" "$LOCAL_BIN/lazygit"
  else
    warn "Could not install lazygit"
  fi
  rm -rf "$tmp"
}

install_herdr_linux() {
  if has herdr; then
    ok "herdr already installed"
    return
  fi
  info "Installing herdr to $LOCAL_BIN..."
  if download "https://github.com/ogulcancelik/herdr/releases/latest/download/herdr-linux-$HERDR_ARCH" "$LOCAL_BIN/herdr"; then
    chmod +x "$LOCAL_BIN/herdr"
  else
    warn "Could not install herdr"
  fi
}

install_linux() {
  case "$(uname -m)" in
    x86_64) NVIM_ARCH=x86_64 LAZYGIT_ARCH=x86_64 HERDR_ARCH=x86_64 ;;
    aarch64 | arm64) NVIM_ARCH=arm64 LAZYGIT_ARCH=arm64 HERDR_ARCH=aarch64 ;;
    *)
      error "Unsupported architecture: $(uname -m)"
      exit 1
      ;;
  esac

  mkdir -p "$LOCAL_BIN" "$LOCAL_OPT"
  [[ ":$PATH:" == *":$LOCAL_BIN:"* ]] || {
    warn "$LOCAL_BIN is not in your PATH. Add it to your shell profile:"
    warn '  export PATH="$HOME/.local/bin:$PATH"'
    export PATH="$LOCAL_BIN:$PATH"
  }

  install_apt_packages
  install_nvim_linux
  install_lazygit_linux
  install_herdr_linux

  # Debian names the binary fdfind; plugins look for fd
  if ! has fd && has fdfind; then
    ln -sfn "$(command -v fdfind)" "$LOCAL_BIN/fd"
    ok "Linked fd -> fdfind"
  fi
}

# ── Shared ────────────────────────────────────────────────────────────────────

install_spell_file() {
  local dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/spell"
  if [[ -f "$dir/es.utf-8.spl" ]]; then
    ok "Spanish spell file already installed"
    return
  fi
  mkdir -p "$dir"
  if download https://ftp.nluug.nl/pub/vim/runtime/spell/es.utf-8.spl "$dir/es.utf-8.spl"; then
    ok "Spanish spell file installed"
  else
    rm -f "$dir/es.utf-8.spl.part"
    warn "Could not download the Spanish spell file; Neovim will offer it on first use"
  fi
}

verify() {
  echo ""
  info "Verifying..."
  local missing=() tool
  for tool in git curl gcc fd rg node npm; do
    if has "$tool"; then ok "$tool"; else
      error "$tool not found"
      missing+=("$tool")
    fi
  done
  if nvim_is_current; then ok "nvim ($(nvim --version | sed -n 1p))"; else
    error "Neovim 0.$NVIM_MIN_MINOR or newer not found"
    missing+=(nvim)
  fi

  local optional=(lazygit herdr claude)
  [[ "$OS" == "macos" ]] && optional+=(magick)
  for tool in "${optional[@]}"; do
    if has "$tool"; then ok "$tool"; else warn "$tool not found (optional)"; fi
  done
  has claude || warn "Install Claude Code from https://claude.ai/download"

  echo ""
  if [[ ${#missing[@]} -gt 0 ]]; then
    error "Missing required tools: ${missing[*]}"
    exit 1
  fi
  ok "Done. Open Neovim and run :checkhealth user"
}

# ── Main ──────────────────────────────────────────────────────────────────────

if [[ "$(uname)" == "Darwin" ]]; then
  OS=macos
  install_macos
elif [[ -f /etc/debian_version ]]; then
  OS=linux
  install_linux
else
  error "Unsupported system. This script supports macOS and Debian/Ubuntu Linux."
  exit 1
fi

install_spell_file
verify
