# User configuration

SCRIPT_DIR="${funcsourcetrace[1]%/*}"

# ZSH History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=$HISTSIZE
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[[A' history-search-backward # up
bindkey '^[[B' history-search-forward  # down

# $PATH configuration
# note: language-specific paths are located in .config/zsh/tools
# path+=("$HOME/.local/bin")

# misc zsh features
autoload -Uz add-zsh-hook

# Load Widgets
source $SCRIPT_DIR/widgets.zsh

# export the path, done here so that the tools configs can add stuff to it
export PATH
