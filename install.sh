#!/usr/bin/env bash
# ==============================================================================
# Terminal Dotfiles Installer (Omarchy / Fedora / Ubuntu)
# Repo: https://github.com/Andyple/terminal-dotfiles
# ==============================================================================

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "[INFO] Installing Terminal Dotfiles from: $DOTFILES_DIR"

ALL_COMPONENTS=("nvim" "tmux" "btop" "fastfetch" "starship" "git" "shell" "alacritty")
ONLY_LIST=()
EXCLUDE_LIST=()
HAS_ONLY=false

usage() {
  cat << EOF
Usage: ./install.sh [OPTIONS]

Options:
  -o, --only <components>               Install ONLY the specified components (comma-separated).
                                        Available: nvim, tmux, btop, fastfetch, starship, git, shell, alacritty
  -x, -e, --exclude, --except <components>
                                        Install all components EXCEPT the specified ones (comma-separated).
  -h, --help                            Show this help message.

Examples:
  ./install.sh                          # Install everything (alacritty only configured if already present)
  ./install.sh --only nvim,tmux         # Install only neovim and tmux
  ./install.sh --only alacritty         # Install alacritty and deploy config even if missing
  ./install.sh --exclude btop,fastfetch # Install everything except btop and fastfetch
EOF
  exit 0
}

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--only)
      if [ -z "$2" ] || [[ "$2" == -* ]]; then
        echo "[ERROR] Option $1 requires an argument."
        exit 1
      fi
      HAS_ONLY=true
      IFS=',' read -ra ADDR <<< "$2"
      for item in "${ADDR[@]}"; do
        ONLY_LIST+=("$item")
      done
      shift 2
      ;;
    -x|-e|--exclude|--except)
      if [ -z "$2" ] || [[ "$2" == -* ]]; then
        echo "[ERROR] Option $1 requires an argument."
        exit 1
      fi
      IFS=',' read -ra ADDR <<< "$2"
      for item in "${ADDR[@]}"; do
        EXCLUDE_LIST+=("$item")
      done
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "[ERROR] Unknown option: $1"
      usage
      ;;
  esac
done

is_enabled() {
  local comp="$1"
  
  if [ "$HAS_ONLY" = true ]; then
    local found=false
    for item in "${ONLY_LIST[@]}"; do
      if [ "$item" = "$comp" ]; then
        found=true
        break
      fi
    done
    if [ "$found" = false ]; then
      return 1
    fi
  fi

  for item in "${EXCLUDE_LIST[@]}"; do
    if [ "$item" = "$comp" ]; then
      return 1
    fi
  done

  # Alacritty rule: if --only is NOT specified, only enable alacritty if already installed on system
  if [ "$comp" = "alacritty" ] && [ "$HAS_ONLY" = false ]; then
    if ! command -v alacritty &>/dev/null; then
      return 1
    fi
  fi

  return 0
}

ACTIVE_COMPONENTS=()
for comp in "${ALL_COMPONENTS[@]}"; do
  if is_enabled "$comp"; then
    ACTIVE_COMPONENTS+=("$comp")
  fi
done

echo "[INFO] Active components to install: ${ACTIVE_COMPONENTS[*]}"

if [ ${#ACTIVE_COMPONENTS[@]} -eq 0 ]; then
  echo "[INFO] No components selected. Exiting."
  exit 0
fi

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

# Check missing essential CLI tools for selected components
NEEDED_PKGS=()
if is_enabled "git" && ! command -v git &>/dev/null; then NEEDED_PKGS+=("git"); fi
if is_enabled "tmux" && ! command -v tmux &>/dev/null; then NEEDED_PKGS+=("tmux"); fi
if is_enabled "nvim" && ! command -v nvim &>/dev/null; then NEEDED_PKGS+=("neovim"); fi
if is_enabled "btop" && ! command -v btop &>/dev/null; then NEEDED_PKGS+=("btop"); fi
if is_enabled "fastfetch" && ! command -v fastfetch &>/dev/null; then NEEDED_PKGS+=("fastfetch"); fi
if is_enabled "alacritty" && ! command -v alacritty &>/dev/null; then NEEDED_PKGS+=("alacritty"); fi

if [ ${#NEEDED_PKGS[@]} -gt 0 ]; then
  echo "Missing packages: ${NEEDED_PKGS[*]}"
  case "$OS" in
    ubuntu|debian)
      sudo apt update && sudo apt install -y "${NEEDED_PKGS[@]}"
      ;;
    fedora|rhel)
      sudo dnf install -y "${NEEDED_PKGS[@]}"
      ;;
    arch|omarchy)
      sudo pacman -S --needed --noconfirm "${NEEDED_PKGS[@]}"
      ;;
    *)
      echo "[WARNING] Unsupported OS ($OS). Please install missing packages manually: ${NEEDED_PKGS[*]}"
      ;;
  esac
else
  echo "[INFO] All core package dependencies for selected components are already installed."
fi

# ------------------------------------------------------------------------------
# 2. Starship Prompt Installation
# ------------------------------------------------------------------------------
if is_enabled "starship"; then
  if ! command -v starship &>/dev/null; then
    echo "[INFO] Installing Starship prompt engine..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  else
    echo "[INFO] Starship prompt is already installed."
  fi
fi

# ------------------------------------------------------------------------------
# 3. Deploy Configs
# ------------------------------------------------------------------------------
echo "[INFO] Deploying selected configurations..."
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

if is_enabled "nvim"; then deploy_config "$DOTFILES_DIR/config/nvim" "$HOME/.config/nvim"; fi
if is_enabled "tmux"; then deploy_config "$DOTFILES_DIR/config/tmux" "$HOME/.config/tmux"; fi
if is_enabled "btop"; then deploy_config "$DOTFILES_DIR/config/btop" "$HOME/.config/btop"; fi
if is_enabled "fastfetch"; then deploy_config "$DOTFILES_DIR/config/fastfetch" "$HOME/.config/fastfetch"; fi
if is_enabled "starship"; then deploy_config "$DOTFILES_DIR/config/starship.toml" "$HOME/.config/starship.toml"; fi
if is_enabled "git"; then deploy_config "$DOTFILES_DIR/config/git" "$HOME/.config/git"; fi
if is_enabled "alacritty"; then deploy_config "$DOTFILES_DIR/config/alacritty" "$HOME/.config/alacritty"; fi

# ------------------------------------------------------------------------------
# 4. Deploy Shell Configuration (~/.bashrc & ~/.bashrc.local)
# ------------------------------------------------------------------------------
if is_enabled "shell"; then
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
fi

echo "=============================================================================="
echo "Terminal environment setup complete."
echo "Run 'source ~/.bashrc' or restart your shell to apply changes."
echo "=============================================================================="
