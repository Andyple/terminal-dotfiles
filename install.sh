#!/usr/bin/env bash
# ==============================================================================
# Terminal Dotfiles Installer (Omarchy / Fedora / Ubuntu)
# Repo: https://github.com/Andyple/terminal-dotfiles
# ==============================================================================

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "🚀 Installing Terminal Dotfiles from: $DOTFILES_DIR"

# ------------------------------------------------------------------------------
# 1. OS Detection & Package Installation
# ------------------------------------------------------------------------------
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
else
  echo "⚠️ Unable to detect OS via /etc/os-release."
  OS="unknown"
fi

echo "📦 Detected OS: $OS"

case "$OS" in
  ubuntu|debian)
    echo "Updating apt and installing dependencies..."
    sudo apt update
    sudo apt install -y git curl zsh tmux neovim btop fzf build-essential
    if ! command -v fastfetch &>/dev/null; then
      sudo apt install -y fastfetch 2>/dev/null || echo "Note: Fastfetch not in apt repos, install manually if needed."
    fi
    ;;
  fedora|rhel)
    echo "Installing packages with dnf..."
    sudo dnf install -y git curl zsh tmux neovim btop fastfetch fzf @development-tools
    ;;
  arch|omarchy)
    echo "Installing packages with pacman..."
    sudo pacman -S --needed --noconfirm git curl zsh tmux neovim btop fastfetch fzf base-devel
    ;;
  *)
    echo "⚠️ Unsupported or unknown OS ($OS). Please ensure git, tmux, neovim, btop, and fastfetch are installed."
    ;;
esac

# ------------------------------------------------------------------------------
# 2. Starship Prompt Installation
# ------------------------------------------------------------------------------
if ! command -v starship &>/dev/null; then
  echo "🌟 Installing Starship prompt engine..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
else
  echo "✅ Starship prompt is already installed."
fi

# ------------------------------------------------------------------------------
# 3. Create ~/.config Subdirectories & Deploy Configs
# ------------------------------------------------------------------------------
echo "🔗 Deploying terminal configurations to ~/.config/ ..."
mkdir -p "$HOME/.config"

deploy_config() {
  local src="$1"
  local dest="$2"

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    echo "  - Backing up existing $dest to ${dest}.bak"
    rm -rf "${dest}.bak"
    mv "$dest" "${dest}.bak"
  fi

  echo "  - Linking $src -> $dest"
  ln -sf "$src" "$dest"
}

deploy_config "$DOTFILES_DIR/config/nvim" "$HOME/.config/nvim"
deploy_config "$DOTFILES_DIR/config/tmux" "$HOME/.config/tmux"
deploy_config "$DOTFILES_DIR/config/btop" "$HOME/.config/btop"
deploy_config "$DOTFILES_DIR/config/fastfetch" "$HOME/.config/fastfetch"
deploy_config "$DOTFILES_DIR/config/starship.toml" "$HOME/.config/starship.toml"
deploy_config "$DOTFILES_DIR/config/git" "$HOME/.config/git"

# ------------------------------------------------------------------------------
# 4. Deploy Shell Configuration (~/.bashrc & ~/.bashrc.local)
# ------------------------------------------------------------------------------
echo "🐚 Deploying shell configuration..."

if [ -f "$HOME/.bashrc" ] && [ ! -L "$HOME/.bashrc" ]; then
  echo "  - Backing up ~/.bashrc to ~/.bashrc.bak"
  cp "$HOME/.bashrc" "$HOME/.bashrc.bak"
fi

ln -sf "$DOTFILES_DIR/shell/bashrc" "$HOME/.bashrc"

if [ ! -f "$HOME/.bashrc.local" ]; then
  echo "  - Initializing ~/.bashrc.local from template"
  cp "$DOTFILES_DIR/templates/bashrc.local.template" "$HOME/.bashrc.local"
fi

echo "=============================================================================="
echo "🎉 Terminal environment setup complete!"
echo "👉 Run 'source ~/.bashrc' or restart your shell to apply changes."
echo "👉 Add any machine-specific secrets/keys to ~/.bashrc.local"
echo "=============================================================================="
