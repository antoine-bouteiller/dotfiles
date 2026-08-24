if [[ -o interactive ]] && (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh --cmd cd)"
fi
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"
(( $+commands[carapace] )) && source <(carapace _carapace zsh)
(( $+commands[mise] )) && eval "$(mise activate zsh)"
(( $+commands[starship] )) && eval "$(starship init zsh)"

if [[ -r "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration ]]; then
  source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
fi
