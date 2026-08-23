export path=(
  $HOME/{,s}bin(N)
  $HOME/.cache/.bun/bin(N)
  $HOME/.local/{,s}bin(N)
  /opt/{homebrew,local}/{,s}bin(N)
  /usr/local/{,s}bin(N)
  $path
)

case $OSTYPE in
  darwin*) export SSH_AUTH_SOCK="$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock" ;;
  linux*) export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock" ;;
esac
