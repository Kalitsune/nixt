# User configuration

SCRIPT_DIR="${funcsourcetrace[1]%/*}"

# ZSH History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY


# $PATH configuration
# note: language-specific paths are located in .config/zsh/tools
# path+=("$HOME/.local/bin")

# welcome screen
fetch () {
  eyes=(0 1 2 3 4 6 7 8 11 12 14)
  $ZSH/bin/cutefetch/cutefetch -k2 $(shuf -e "${eyes[@]}" -n 1)
}
fetch

# misc zsh features
autoload -Uz add-zsh-hook

# Load Widgets
source $SCRIPT_DIR/widgets.zsh

# export the path, done here so that the tools configs can add stuff to it
export PATH
