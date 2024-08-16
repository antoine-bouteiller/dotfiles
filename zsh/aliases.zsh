alias ll="ls -all"
alias zshconfig="vim ~/.zshrc"
alias gclean='git fetch -p && for branch in $(git for-each-ref --format '\''%(refname) %(upstream:track)'\'' refs/heads | awk '\''$2 == "[gone]" {sub("refs/heads/", "", $1); print $1}'\''); do git branch -D $branch; done'
alias gps='git checkout staging && git rebase develop && gpf!'
alias gpp='git checkout production && git rebase staging && gpf!'
alias bua='bup && bcup && bcn'
