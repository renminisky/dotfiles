#!/usr/bin/env bash

# ────────────────────────────────────
#           Execution Guards                                   
# ────────────────────────────────────

error_guard() {
    printf "\033[31m[Error]\033[0m %s\n" "$1" >&2
}

# Prevent the script from being sourced
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    error_guard "This script is being sourced. Please execute it instead."
    return 1
fi

# Prevent running as root
if [[ $EUID -eq 0 ]]; then
    error_guard "Don't run this script as root"
    exit 1
fi


# ─────────────────────────────────────────
#           Setup & Configuration                                                             
# ─────────────────────────────────────────

set -euo pipefail

# ANSI color codes
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
GRAY='\033[38;5;239m'
NC='\033[0m'

XDG_CONFIG_HOME="$HOME/.config"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZDOTDIR="$DIR/zsh"
CONFIG_DIR="$DIR/config"
PRIVATE_DIR="$DIR/private_config"
TEMPLATE_DIR="$DIR/private_config/templates"

LOG_FILE="/tmp/dotfiles-install-$(date +%Y%m%d-%H%M%S).log"
SYSTEM_ZSHENV_FILE="/etc/zsh/zshenv"

done_() {
    printf "${GREEN}[Done]${NC} $1\n"
    printf "[Done] $1\n" >> "$LOG_FILE"
}

error() {
    printf "${RED}[Error]${NC} %s\n" "$1" >&2
    if [[ -f "$LOG_FILE" ]]; then
        printf "${RED}Last 10 lines from log (${LOG_FILE}):${NC}\n" >&2
        printf "${RED}==============================${GRAY}\n"
        tail -10 "$LOG_FILE" >&2
        printf "${RED}==============================${NC}\n"
    fi
    exit 1
}

error_no_log() {
    printf "${RED}[Error]${NC} %s\n" "$1" >&2
    exit 1
}

spinner() {
    local message=$1
    local pid=$2
    local delay=0.1
    local spinstr='|/-\'

    while kill -0 "$pid" 2>/dev/null; do
        for (( i=0; i<${#spinstr}; i++ )); do
            printf "\r${YELLOW}[In Progress]${NC} %s %s" "$message" "${spinstr:i:1}"
            sleep $delay
        done
    done
    printf "\r%-*s\r" "$(tput cols)" ""

    # Wait for pid and capture status
    if wait "$pid"; then
        done_ "$message"
    else
        error "$message"
    fi
}


# ────────────────────────────────
#           Installation                                        
# ────────────────────────────────


printf "This installation log is output into ${LOG_FILE}\n"


## ─── Keep sudo alive ──────────────────────────────


sudo -v  # prompt password once
(
    while true; do
        sudo -n true
        sleep 60
    done
) &

sudo_keeper_pid=$!
trap 'kill $sudo_keeper_pid 2>/dev/null' EXIT


## ─── Install apt packages ──────────────────────────────


if ! command -v apt &>/dev/null; then
    error_no_log "This script requires apt package manager (Debian/Ubuntu)"
fi

sudo bash -c 'apt update && apt install -y build-essential procps curl file git wget zsh' &>> "$LOG_FILE" &
pid=$!
spinner "Installing apt packages" "$pid"


## ─── Change default shell to zsh ──────────────────────────────


if [[ "$SHELL" != *"zsh" ]]; then
    if command -v zsh &>/dev/null; then
        sudo chsh -s "$(command -v zsh)" 2>&1 | tee -a "$LOG_FILE"
        done_ "Changing default shell to zsh"
    else
        error "zsh is not installed"
    fi
else
    done_ "Zsh is already the default shell"
fi


## ─── Set zsh directory ──────────────────────────────


# Check if the file exists
if [[ ! -f "$SYSTEM_ZSHENV_FILE" ]]; then
    error_no_log "$SYSTEM_ZSHENV_FILE does not exist. Cannot set ZDOTDIR."
fi

# Append ZDOTDIR only if not already set
if ! grep -Eq '^[[:space:]]*export[[:space:]]+ZDOTDIR=' "$SYSTEM_ZSHENV_FILE" 2>/dev/null; then
    if [[ -z "$(tail -n 1 "$SYSTEM_ZSHENV_FILE" | tr -d '[:space:]')" ]]; then
        # Last line is empty → just append without adding another newline
        printf 'export ZDOTDIR="%s"\n' "$ZDOTDIR" | sudo tee -a "$SYSTEM_ZSHENV_FILE" >/dev/null
    else
        # Last line is not empty → insert a newline before appending
        printf '\nexport ZDOTDIR="%s"\n' "$ZDOTDIR" | sudo tee -a "$SYSTEM_ZSHENV_FILE" >/dev/null
    fi
    done_ "added ZDOTDIR to $SYSTEM_ZSHENV_FILE"
else
    done_ "ZDOTDIR already set in $SYSTEM_ZSHENV_FILE"
fi


## ─── Install Homebrew packages ──────────────────────────────


# This should be after the last sudo command in script because it breaks sudo alive loop

# Install Homebrew
if command -v brew &>/dev/null; then
    done_ "Homebrew is already installed at $(command -v brew)"
else
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &>> "$LOG_FILE" &
    pid=$!
    spinner "Installing Homebrew" "$pid"
fi

# Set up Homebrew environment
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install Homebrew packages
brew bundle --file "$DIR/Brewfile" &>> "$LOG_FILE" &
pid=$!
spinner "Installing Homebrew packages" "$pid"


## ─── Stow configs ──────────────────────────────


[ ! -d "$XDG_CONFIG_HOME" ] && mkdir -p "$XDG_CONFIG_HOME" 2>&1 | tee -a "$LOG_FILE"
stow --dir="$CONFIG_DIR" --target="$XDG_CONFIG_HOME" . --no-folding 2>&1 | tee -a "$LOG_FILE"

done_ "Stowed config files"


## ─── Create private config files ──────────────────────────────


# git
[ ! -f "$PRIVATE_DIR/gitconfig.private" ] && cp "$TEMPLATE_DIR/gitconfig.private.template" "$PRIVATE_DIR/gitconfig.private"
ln -sf "$PRIVATE_DIR/gitconfig.private" "$XDG_CONFIG_HOME/git/config.private"

done_ "Created private config"


## ─── Final message ──────────────────────────────


printf "${GREEN}Installation completed successfully!${NC}\n"
printf "Restart your shell with 'exec zsh' to apply changes.\n"