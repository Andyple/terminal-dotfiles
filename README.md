# 💻 Terminal Dotfiles

Cross-platform Linux terminal configuration repository powering an identical workflow across **Omarchy (Arch Linux)**, **Fedora**, and **Ubuntu** Virtual Machines.

---

## ⚡ Features Included

- 📝 **Neovim** (`~/.config/nvim`): Custom editor configuration and plugin suite.
- 🖥️ **Tmux** (`~/.config/tmux/tmux.conf`): Vi copy mode, custom pane/window navigation (`Alt+1..9`, `Ctrl+Meta` split keys), theme styling.
- 📊 **Btop** (`~/.config/btop/btop.conf`): Resource monitoring layout and theme.
- ℹ️ **Fastfetch** (`~/.config/fastfetch/config.jsonc`): Fastfetch layout.
- 🚀 **Starship Prompt** (`~/.config/starship.toml`): Fast, cyan-themed shell prompt displaying git status, current directory, and execution status.
- 🔧 **Git Config** (`~/.config/git/config`): Presets (`co`, `br`, `ci`, `st`), histogram diffs, rebase on pull, branch sorting.
- 🐚 **Bash Environment** (`~/.bashrc`): Custom aliases (`la='ls -al'`), helper functions (`dagent-up`, `dagent-down`, `dagent-connect`), and support for machine-specific secrets (`~/.bashrc.local`).

---

## 🚀 One-Command VM Installation

On any fresh **Fedora**, **Ubuntu**, or **Arch Linux / Omarchy** system:

```bash
git clone https://github.com/Andyple/terminal-dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

Or run directly via curl:

```bash
curl -fsSL https://raw.githubusercontent.com/Andyple/terminal-dotfiles/main/install.sh | bash
```

---

## 🔒 Private Keys & Machine-Specific Overrides

Private API keys (such as `LLAMA_API_KEY`) and machine-specific variables are isolated in `~/.bashrc.local`, which is **never tracked in Git**.

To set up machine keys:

```bash
nano ~/.bashrc.local
```
