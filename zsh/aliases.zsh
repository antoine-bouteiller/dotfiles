alias ll="ls -all"
alias zshconfig="vim ~/.zshrc"
alias ga="git add ./"
alias gc='git commit'
alias gp='git push --force-with-lease'
alias git-clean='git fetch -p && for branch in $(git for-each-ref --format '\''%(refname) %(upstream:track)'\'' refs/heads | awk '\''$2 == "[gone]" {sub("refs/heads/", "", $1); print $1}'\''); do git branch -D $branch; done'

# Update node versions
function nvm_update() {
    local prev_ver=$(nvm version ${1:-"lts/*"})
    nvm install ${1:-"lts/*"} --latest-npm
    if [ "$prev_ver" != "$(nvm current)" ]; then
        nvm reinstall-packages $prev_ver
        nvm uninstall $prev_ver
    fi
    nvm cache clear
}
