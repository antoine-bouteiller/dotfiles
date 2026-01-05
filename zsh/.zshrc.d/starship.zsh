(( $+commands[starship] )) || return 1
export STARSHIP_CONFIG="$DOTDIR/starship.toml"
eval "$(starship init zsh)"
