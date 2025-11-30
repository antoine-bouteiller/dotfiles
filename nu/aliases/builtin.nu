# replace native common commands with better defaults
# export alias ls = eza --group-directories-first --icons
export alias cat = bat --paging=never
export alias grep = rg

# single character aliases - be sparing!
export alias _ = sudo
export alias l = ls
export alias g = git

# mask built-ins with better defaults
export alias vi = vim

# more ways to ls
export alias ll = ls -l
export alias la = ls -la
export alias ldot = ls -ld .*
