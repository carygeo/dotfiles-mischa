#!/usr/bin/env bash
set -euo pipefail

# Fedora Atomic COSMIC-friendly bootstrap
# - Keeps host lean
# - Puts dev tooling in toolbox
# - Works on Silverblue/Kinoite/Sericea/COSMIC Atomic variants

TOOLBOX_NAME="dev"
FEDORA_VERSION="$(rpm -E %fedora 2>/dev/null || echo 43)"

log() { printf "\n==> %s\n" "$*"; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1"
    exit 1
  }
}

log "Preflight"
require_cmd rpm-ostree
require_cmd flatpak
require_cmd toolbox

log "Layer minimal host packages (requires reboot if changed)"
# Keep host lean: terminal + display/session helpers + git/ssh
sudo rpm-ostree install \
  git openssh-clients curl wget \
  tmux zsh neovim ripgrep fd-find fzf \
  direnv jq yq \
  alacritty \
  podman podman-compose

log "Install desktop apps via Flatpak"
flatpak install -y flathub \
  md.obsidian.Obsidian \
  com.vivaldi.Vivaldi \
  org.mozilla.firefox || true

log "Create/ensure toolbox container: ${TOOLBOX_NAME}"
if ! toolbox list | grep -q "${TOOLBOX_NAME}"; then
  toolbox create --container "${TOOLBOX_NAME}" --distro fedora --release "${FEDORA_VERSION}"
fi

log "Install dev stack inside toolbox"
toolbox run --container "${TOOLBOX_NAME}" bash -lc '
set -euo pipefail
sudo dnf install -y \
  gcc gcc-c++ make cmake unzip \
  python3 python3-pip pipx uv \
  nodejs npm \
  go cargo rust \
  neovim tmux zsh \
  ripgrep fd-find fzf bat eza zoxide \
  gh lazygit \
  direnv jq yq shellcheck shfmt

# Prompt + shell helpers
mkdir -p "$HOME/.zsh"
if [ ! -d "$HOME/.zsh/pure" ]; then
  git clone https://github.com/sindresorhus/pure.git "$HOME/.zsh/pure"
fi

pipx ensurepath || true
'

log "Done"
echo "If rpm-ostree installed new packages, reboot once."
echo "Then enter your dev container with: toolbox enter ${TOOLBOX_NAME}"
