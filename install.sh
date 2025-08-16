#!/usr/bin/env bash
set -euo pipefail

# ANSI color codes
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
NC='\033[0m'

LOG_FILE="/tmp/dotfiles-install-$(date +%Y%m%d-%H%M%S).log"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

done_() {
    local message="${GREEN}[Done]${NC} $1\n"
    printf "$message"
    printf "$message" >> "$LOG_FILE"
}

error() {
    printf "${RED}[Error]${NC} %s\n" "$1" >&2
    if [[ -f "$LOG_FILE" ]]; then
        printf "${RED}Last 10 lines from log:${NC}\n" >&2
        tail -10 "$LOG_FILE" >&2
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


# ─────────────────────────────────────
#              MAIN SCRIPT                  
# ─────────────────────────────────────


# Several guard clause checks before proceeding
if [[ $EUID -ne 0 ]]; then
    error_no_log "This script requires root privileges. Please run it with: sudo ${BASH_SOURCE[0]}"
fi

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    printf "${RED}[Error]${NC} This script is being sourced. Please execute it instead.\n" >&2
    return 1
fi


# Install apt packages
if ! command -v apt &>/dev/null; then
    error_no_log "This script requires apt package manager (Debian/Ubuntu)"
fi

(sudo bash -c 'apt update && apt install -y build-essential procps curl file git wget zsh' &>> "$LOG_FILE") &
pid=$!
spinner "installing apt packages" "$pid"


# Install Homebrew packages
if command -v brew &>/dev/null; then
    done_ "brew is already installed at $(command -v brew)"
else
    (bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &>> "$LOG_FILE") &
    pid=$!
    spinner "installing brew" "$pid"
fi

(brew bundle --file "$DIR/Brewfile" &>> "$LOG_FILE") &
pid=$!
spinner "installing brew packages" "$pid"
