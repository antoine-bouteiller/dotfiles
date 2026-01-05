(( $+commands[mise] )) || return 1
eval "$(mise activate zsh)"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
