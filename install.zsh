#!/usr/bin/env zsh

set -eu
setopt PIPE_FAIL

RED=$'\033[31m'
GREEN=$'\033[32m'
NC=$'\033[0m'

done_() {
    printf "%s[Done] %s%s\n" "$GREEN" "$1" "$NC"
}

error() {
    printf "%s[Error] %s%s\n" "$RED" "$1" "$NC"
    exit 1
}

## ─────────────────────────────────────────────────────────────────
##           Setup zshenv variables
## ─────────────────────────────────────────────────────────────────

DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
ZDOTDIR="$DIR/zsh"

if [[ ! -f "$ZDOTDIR/.zshenv" ]]; then
    error "zshenv not found"
fi
source "$ZDOTDIR/.zshenv"


## ─────────────────────────────────────────────────────────────────
##           Set ZDOTDIR in /etc/zsh/zshenv
## ─────────────────────────────────────────────────────────────────

SYSTEM_ZSHENV_FILE="/etc/zsh/zshenv"

# Check if the file exists
if [[ ! -f "$SYSTEM_ZSHENV_FILE" ]]; then
    error "$SYSTEM_ZSHENV_FILE does not exist. Cannot set ZDOTDIR."
fi

# Append ZDOTDIR only if not already set
if ! grep -Eq '^[[:space:]]*export[[:space:]]+ZDOTDIR=' "$SYSTEM_ZSHENV_FILE"; then
    last_line=$(tail -n 1 "$SYSTEM_ZSHENV_FILE")
    if [[ -z "${last_line//[[:space:]]/}" ]]; then
        # Last line is empty → just append without adding another newline
        printf 'export ZDOTDIR="%s"\n' "$ZDOTDIR" | sudo tee -a "$SYSTEM_ZSHENV_FILE" >/dev/null
    else
        # Last line is not empty → insert a newline before appending
        printf '\nexport ZDOTDIR="%s"\n' "$ZDOTDIR" | sudo tee -a "$SYSTEM_ZSHENV_FILE" >/dev/null
    fi
    done_ "Added ZDOTDIR to $SYSTEM_ZSHENV_FILE"
else
    done_ "ZDOTDIR already set in $SYSTEM_ZSHENV_FILE"
fi


## ─────────────────────────────────────────────────────────────────
##           Install Homebrew packages
## ─────────────────────────────────────────────────────────────────

# Install Homebrew
if command -v brew &>/dev/null; then
    done_ "Homebrew is already installed at $(command -v brew)"
else
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    done_ "Installed Homebrew"
fi

# Set up Homebrew environment
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install Homebrew packages
brew bundle --file "$DIR/Brewfile"
done_ "Installed Homebrew packages"


## ─────────────────────────────────────────────────────────────────
##           Setup stow
## ─────────────────────────────────────────────────────────────────

CONFIG_DIR="$DIR/config"

mkdir -p "$XDG_CONFIG_HOME"
stow --dir="$CONFIG_DIR" --target="$XDG_CONFIG_HOME" . --no-folding

done_ "Setup stow"


## ─────────────────────────────────────────────────────────────────
##           Create private config files
## ─────────────────────────────────────────────────────────────────

PRIVATE_DIR="$DIR/private_config"
TEMPLATE_DIR="$DIR/private_config/templates"

# git
[[ ! -f "$PRIVATE_DIR/gitconfig.private" ]] && cp "$TEMPLATE_DIR/gitconfig.private.template" "$PRIVATE_DIR/gitconfig.private"
ln -sf "$PRIVATE_DIR/gitconfig.private" "$XDG_CONFIG_HOME/git/config.private"

done_ "Created private config files"


## ─── Final message ──────────────────────────────

printf "%sInstallation completed successfully!%s\n" "$GREEN" "$NC"
printf "%sRestart your shell with %s'exec zsh'%s to apply changes.%s\n" "$GREEN" "$RED" "$GREEN" "$NC"