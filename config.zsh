# Initialisation d'Antigen
source /opt/homebrew/opt/antigen/share/antigen/antigen.zsh

antigen use oh-my-zsh

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

for config in "${CONFIG_DIR}/zsh/"*.zsh; do
	source $config
done
