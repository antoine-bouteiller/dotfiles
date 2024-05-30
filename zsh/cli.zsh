# direnv
eval "$(direnv hook zsh)"

# nvm
export NVM_COMPLETION=true
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"                                       # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

eval $(thefuck --alias)

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# terraform autocomplete
complete -o nospace -C /opt/homebrew/bin/terraform terraform
autoload -U +X bashcompinit && bashcompinit

export CODEARTIFACT_AUTH_TOKEN=$(aws codeartifact get-authorization-token --domain lty --domain-owner 364087620918 --region eu-west-3 --query authorizationToken --output text --profile lty)

# Load Angular CLI autocompletion.
source <(ng completion script)

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
