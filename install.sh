#!/usr/bin/env bash
# ==============================================================================
# Terminal Dotfiles Installer (Omarchy / Fedora / Ubuntu)
# Repo: https://github.com/Andyple/terminal-dotfiles
# ==============================================================================

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "[INFO] Installing Terminal Dotfiles from: $DOTFILES_DIR"

# ------------------------------------------------------------------------------
# 1. OS Detection & Package Installation
# ------------------------------------------------------------------------------
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
else
  echo "[WARNING] Unable to detect OS via /etc/os-release."
  OS="unknown"
fi

echo "[INFO] Detected OS: $OS"

# Check missing essential CLI tools
NEEDED_PKGS=()
for pkg in git curl tmux nvim btop fastfetch fzf; do
  if ! command -v "$pkg" &>/dev/null; then
    NEEDED_PKGS+=("$pkg")
  fi
done

if [ ${#NEEDED_PKGS[@]} -gt 0 ]; then
  echo "Missing packages: ${NEEDED_PKGS[*]}"
  case "$OS" in
    ubuntu|debian)
      sudo apt update && sudo apt install -y git curl zsh tmux neovim btop fzf build-essential
      ;;
    fedora|rhel)
      sudo dnf install -y git curl zsh tmux neovim btop fastfetch fzf @development-tools
      ;;
    arch|omarchy)
      sudo pacman -S --needed --noconfirm git curl zsh tmux neovim btop fastfetch fzf base-devel
      ;;
    *)
      echo "[WARNING] Unsupported OS ($OS). Please ensure git, tmux, neovim, btop, and fastfetch are installed."
      ;;
  esac
else
  echo "[INFO] All core package dependencies (git, tmux, nvim, btop, fastfetch, fzf) are already installed."
fi

# ------------------------------------------------------------------------------
# 2. Starship Prompt Installation
# ------------------------------------------------------------------------------
if ! command -v starship &>/dev/null; then
  echo "[INFO] Installing Starship prompt engine..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
else
  echo "[INFO] Starship prompt is already installed."
fi

# ------------------------------------------------------------------------------
# 3. Create ~/.config Subdirectories & Deploy Configs
# ------------------------------------------------------------------------------
echo "[INFO] Deploying terminal configurations to ~/.config/ ..."
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
echo "[INFO] Deploying shell configuration..."

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
echo "Terminal environment setup complete."
echo "Run 'source ~/.bashrc' or restart your shell to apply changes."
echo "Add any machine-specific secrets/keys to ~/.bashrc.local"
echo "=============================================================================="
