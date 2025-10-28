
# replace native common commands with better defaults
alias ls='eza --group-directories-first --icons'
alias cat='bat --paging=never'

# single character aliases - be sparing!
alias _=sudo
alias l='ls'
alias g=git

# mask built-ins with better defaults
alias vi=vim

# more ways to ls
alias ll='ls -l'
alias la='ls -la'
alias ldot='ls -ld .*'

# more git alias
alias gclean='git fetch -p && for branch in $(git for-each-ref --format '\''%(refname) %(upstream:track)'\'' refs/heads | awk '\''$2 == "[gone]" {sub("refs/heads/", "", $1); print $1}'\''); do git branch -D $branch; done'
alias gps='git checkout staging && git rebase develop && gpf'
alias gpp='git checkout production && git rebase staging && gpf'

# fix common typos
alias quit='exit'
alias cd..='cd ..'

# tar
alias tarls="tar -tvf"
alias untar="tar -xf"

# find
# alias fd='find . -type d -name'
# alias ff='find . -type f -name'

# brew
alias bua='bup && bcup --greedy && bcn'

# misc
alias please=sudo
alias zshrc='${EDITOR:-vim} "${ZDOTDIR:-$HOME}"/.zshrc'
alias zdot='cd ${ZDOTDIR:-~}'
