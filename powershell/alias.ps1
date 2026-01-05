Import-Module git-aliases -DisableNameChecking


Remove-Item Alias:ls -ErrorAction SilentlyContinue
Remove-Item Alias:cat -ErrorAction SilentlyContinue
# replace native common commands with better defaults
function ls { eza --group-directories-first --icons @Args }
function cat { bat --paging=never @Args }

Set-Alias vi vim
Set-Alias g git
Set-Alias l ls

# sudo equivalent (use gsudo on Windows, sudo in WSL)
function _ { gsudo @Args }

# more ways to ls
function ll   { ls -l  @Args }
function la   { ls -la @Args }
function ldot { ls -ld .* @Args }

# git helpers
function gclean {
    git fetch -p
    git for-each-ref --format='%(refname) %(upstream:track)' refs/heads |
        Where-Object { $_ -match '\[gone\]' } |
        ForEach-Object {
            ($_ -split ' ')[0] -replace '^refs/heads/', ''
        } |
        ForEach-Object {
            git branch -D $_
        }
}
