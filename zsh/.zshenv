# XDG paths
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker
alias wget=wget --hsts-file="$XDG_DATA_HOME/wget-hsts"