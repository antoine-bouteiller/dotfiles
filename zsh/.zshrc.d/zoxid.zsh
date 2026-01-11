(( $+commands[zoxide] )) || curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
eval "$(zoxide init zsh --cmd cd)"

_cd_with_zoxide() {
    local cur="${words[CURRENT]}"
    local -a zoxide_dirs
    local ret=1

    # Get last 10 zoxide results
    if [[ -n "$cur" ]]; then
        zoxide_dirs=("${(@f)$(zoxide query --list -- "$cur" 2>/dev/null | head -10)}")
    else
        zoxide_dirs=("${(@f)$(zoxide query --list 2>/dev/null | head -10)}")
    fi

    # Show default cd completions
    _cd && ret=0

    # Show zoxide results
    if (( ${#zoxide_dirs[@]} )); then
        _describe -t zoxide-dirs 'zoxide' zoxide_dirs && ret=0
    fi

    return $ret
}

# Override cd completion with our custom function
compdef _cd_with_zoxide cd
