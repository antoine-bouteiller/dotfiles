(( $+commands[thefuck] )) || { [[ "$OSTYPE" == *darwin* ]] && brew install thefuck || (grep -qi "fedora" /etc/os-release && sudo dnf install -y thefuck); }
eval $(thefuck --alias)