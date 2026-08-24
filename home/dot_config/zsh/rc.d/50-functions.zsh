function lg() {
    export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
    command lazygit "$@"
    if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
      cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
      rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
    fi
}

pi() {
  AZURE_OPENAI_BASE_URL="https://pelico-openai-poc.openai.azure.com/openai" \
  AZURE_OPENAI_API_KEY="$(chezmoi secret keyring get --service=openai --user=AZURE_OPENAI_API_KEY)" \
    command pi "$@"
}

runenv() {
  emulate -L zsh
  local ns="env"
  # first arg is the namespace only if secrets/<arg>.yaml exists, else default to env.yaml
  local secrets_dir="$HOME/.dotfiles/hosts/pelico/secrets"
  if [[ -f "$secrets_dir/$1.yaml" ]]; then ns="$1"; shift; fi
  # ${(@q)@} quotes each arg so spaces survive sops's single command string
  sops exec-env "$secrets_dir/$ns.yaml" "${(j: :)${(@q)@}}"
}
