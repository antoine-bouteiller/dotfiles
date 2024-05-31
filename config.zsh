CONFIG_DIR=$(dirname "$(readlink -f "$0")")

# Initialisation d'Antigen
source "${CONFIG_DIR}/zsh/antigen.zsh"

antigen use oh-my-zsh

export NVM_COMPLETION=true
antigen bundle lukechilds/zsh-nvm

antigen bundle git
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle brew
antigen bundle colorize
antigen bundle dirhistory
antigen bundle sudo

antigen theme romkatv/powerlevel10k

# Appliquer l'ensemble des changements
antigen apply

source "${CONFIG_DIR}/zsh/aliases.zsh"
source "${CONFIG_DIR}/zsh/cli.zsh"
