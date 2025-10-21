(is-macos && (( $+commands[brew] )))  || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval $(brew shellenv)
