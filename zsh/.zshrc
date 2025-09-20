# Put this on top of the script because of instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

mkdir -p "$XDG_STATE_HOME/zsh"
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=1000000
SAVEHIST=1000000

# Append to history file, don't overwrite it
setopt INC_APPEND_HISTORY
# Before each command, update local shell history with history file
autoload -Uz add-zsh-hook
add-zsh-hook precmd() { fc -RI }
# Remove older duplicate from history file when adding same new command
setopt HIST_IGNORE_ALL_DUPS
# Don't show duplicates in history search
setopt HIST_FIND_NO_DUPS

# Activate homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Activate p10k
source $HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme

# Load p10k config
[[ ! -f ~/.dotfiles/zsh/p10k.zsh ]] || source ~/.dotfiles/zsh/p10k.zsh

# zsh-syntax-highlighting
source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# zsh-autosuggestions
source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-autocomplete
source $HOMEBREW_PREFIX/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh

bindkey              '^I'         menu-complete
bindkey "$terminfo[kcbt]" reverse-menu-complete