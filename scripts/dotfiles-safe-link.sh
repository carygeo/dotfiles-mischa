#!/usr/bin/env bash
set -euo pipefail

# Safer symlink deploy for dotfiles repos.
# - Backs up existing files/directories into ~/.dotfiles-backup/<timestamp>
# - Creates parent dirs
# - Forces symlink updates cleanly

DOTFILES_DIR="${1:-$HOME/Repos/github.com/carygeo/dotfiles-mischa}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP_DIR"

log() { printf "==> %s\n" "$*"; }

backup_if_exists() {
  local target="$1"
  if [ -L "$target" ] || [ -e "$target" ]; then
    local rel
    rel="${target#$HOME/}"
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    mv "$target" "$BACKUP_DIR/$rel"
    log "Backed up $target -> $BACKUP_DIR/$rel"
  fi
}

link_item() {
  local source="$1"
  local target="$2"
  mkdir -p "$(dirname "$target")"
  backup_if_exists "$target"
  ln -s "$DOTFILES_DIR/$source" "$target"
  log "Linked $source -> $target"
}

# Core cross-platform targets
link_item ".tmux.conf" "$HOME/.tmux.conf"
link_item "alacritty.toml" "$XDG_CONFIG_HOME/alacritty/alacritty.toml"
link_item "nvim" "$XDG_CONFIG_HOME/nvim"
link_item ".inputrc" "$HOME/.inputrc"
link_item ".zprofile" "$HOME/.zprofile"
link_item ".zshrc" "$HOME/.zshrc"

# Optional Linux WM/browser configs from this repo (enable as desired)
if [ "${ENABLE_HYPR:-0}" = "1" ]; then
  link_item "hypr/hyprland.conf" "$XDG_CONFIG_HOME/hypr/hyprland.conf"
  link_item "hypr/hypridle.conf" "$XDG_CONFIG_HOME/hypr/hypridle.conf"
  link_item "hypr/hyprlock.conf" "$XDG_CONFIG_HOME/hypr/hyprlock.conf"
fi

if [ "${ENABLE_QUTEBROWSER:-0}" = "1" ]; then
  link_item "qutebrowser/config.py" "$XDG_CONFIG_HOME/qutebrowser/config.py"
fi

log "Done. Backups are in: $BACKUP_DIR"
