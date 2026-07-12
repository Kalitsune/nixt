# Ensure terminal enters application mode while ZLE is active so that
# $terminfo sequences are valid (required for the bindings below).
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
  zle-line-init()   { echoti smkx }
  zle-line-finish() { echoti rmkx }
  zle -N zle-line-init
  zle -N zle-line-finish
fi

bindkey -e

# [PageUp / PageDown] - history navigation
[[ -n "${terminfo[kpp]}" ]] && bindkey -M emacs "${terminfo[kpp]}" up-line-or-history
[[ -n "${terminfo[knp]}" ]] && bindkey -M emacs "${terminfo[knp]}" down-line-or-history

# [Up / Down] - prefix-aware history search
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey -M emacs "^[[A" up-line-or-beginning-search
bindkey -M emacs "^[[B" down-line-or-beginning-search
[[ -n "${terminfo[kcuu1]}" ]] && bindkey -M emacs "${terminfo[kcuu1]}" up-line-or-beginning-search
[[ -n "${terminfo[kcud1]}" ]] && bindkey -M emacs "${terminfo[kcud1]}" down-line-or-beginning-search

# [Home / End]
[[ -n "${terminfo[khome]}" ]] && bindkey -M emacs "${terminfo[khome]}" beginning-of-line
[[ -n "${terminfo[kend]}"  ]] && bindkey -M emacs "${terminfo[kend]}"  end-of-line

# [Shift-Tab] - reverse completion menu
[[ -n "${terminfo[kcbt]}" ]] && bindkey -M emacs "${terminfo[kcbt]}" reverse-menu-complete

# [Backspace] - delete backward
bindkey -M emacs '^?' backward-delete-char

# [Delete] - delete forward
if [[ -n "${terminfo[kdch1]}" ]]; then
  bindkey -M emacs "${terminfo[kdch1]}" delete-char
else
  bindkey -M emacs "^[[3~"  delete-char
  bindkey -M emacs "^[3;5~" delete-char
fi

# [Ctrl-Delete] - delete whole forward word
bindkey -M emacs '^[[3;5~' kill-word

# [Ctrl-Left / Ctrl-Right] - word navigation
bindkey -M emacs '^[[1;5D' backward-word
bindkey -M emacs '^[[1;5C' forward-word

# [Esc-w] - kill from cursor to mark
bindkey '\ew' kill-region

# [Esc-l] - run ls
bindkey -s '\el' '^q ls\n'

# [Ctrl-r] - incremental history search
bindkey '^r' history-incremental-search-backward

# [Esc-m] - copy previous shell word
bindkey '^[m' copy-prev-shell-word

# [Ctrl-x Ctrl-e] - open buffer in editor
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '\C-x\C-e' edit-command-line

# [Ctrl-x Ctrl-l] - clear screen, keep buffer
clear-keep-buffer() {
    clear
    fetch
    zle reset-prompt
    zle redisplay
}
zle -N clear-keep-buffer
bindkey '^x^l' clear-keep-buffer

# [Ctrl-x Ctrl-c] - copy current command to clipboard
copy-command() {
    echo -n $BUFFER | wl-copy
    zle -M "Copied to clipboard"
}
zle -N copy-command
bindkey '^x^c' copy-command
