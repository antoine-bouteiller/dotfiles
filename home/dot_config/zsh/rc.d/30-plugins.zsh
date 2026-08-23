# Plugins managed by chezmoi externals
ZSH_AUTOSUGGEST_STRATEGY=(history)
[[ -f "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] &&
  source "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

if [[ -f "$HOME/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh" ]]; then
  source "$HOME/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh"
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey '^[OA' history-substring-search-up
  bindkey '^[OB' history-substring-search-down
fi
