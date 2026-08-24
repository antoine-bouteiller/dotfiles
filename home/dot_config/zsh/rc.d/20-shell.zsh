autoload -U compinit && compinit

# Completion styles
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'

# Emacs keymap (zsh would otherwise pick viins from $EDITOR=nvim)
bindkey -e

bindkey '^[^?' backward-kill-word
bindkey '^[^H' backward-kill-word
# ctrl+arrows, not alt+arrows: AeroSpace grabs alt-left/right globally for 'focus'
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# History options
HISTSIZE="50000"
SAVEHIST="50000"
HISTFILE="$HOME/.zsh_history"
mkdir -p "$(dirname "$HISTFILE")"

set_opts=(
  HIST_FCNTL_LOCK EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS
  HIST_IGNORE_SPACE SHARE_HISTORY NO_APPEND_HISTORY NO_HIST_FIND_NO_DUPS
  NO_HIST_IGNORE_ALL_DUPS NO_HIST_SAVE_NO_DUPS
)
for opt in "${set_opts[@]}"; do
  setopt "$opt"
done
unset opt set_opts
