Remove-Alias gc -Force -ErrorAction SilentlyContinue
Remove-Alias gcb -Force -ErrorAction SilentlyContinue
Remove-Alias gcm -Force -ErrorAction SilentlyContinue
Remove-Alias gcs -Force -ErrorAction SilentlyContinue
Remove-Alias gl -Force -ErrorAction SilentlyContinue
Remove-Alias gm -Force -ErrorAction SilentlyContinue
Remove-Alias gp -Force -ErrorAction SilentlyContinue
Remove-Alias gpv -Force -ErrorAction SilentlyContinue

function Get-Git-MainBranch
{
    git rev-parse --git-dir *> $null

    if ($LASTEXITCODE -ne 0)
    {
        return
    }

    $branches = @('main', 'trunk')

    foreach ($branch in $branches)
    {
        & git show-ref -q --verify refs/heads/$branch

        if ($LASTEXITCODE -eq 0)
        {
            return $branch
        }
    }

    return 'master'
}

function g
{
    git $args
}
function gaa
{
    git add --all @args
}
function gaa
{
    git add --all $args
}
function gb
{
    git branch $args
}
function gbd
{
    git branch -d $args
}
function gc
{
    git commit -v $args
}
function gc!
{
    git commit -v --amend $args
}
function gcn!
{
    git commit -v --no-edit --amend $args
}
function gca
{
    git commit -v -a $args
}
function gcam
{
    git commit -a -m $args
}
function gca!
{
    git commit -v -a --amend $args
}
function gcan!
{
    git commit -v -a --no-edit --amend $args
}
function gcb
{
    git checkout -b $args
}
function gcl
{
    git clone --recursive $args
}
function gco
{
    git checkout $args
}
function gclean
{
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
function gcp
{
    git cherry-pick $args
}
function gcpa
{
    git cherry-pick --abort $args
}
function gcpc
{
    git cherry-pick --continue $args
}
function gf
{
    git fetch $args
}
function gl
{
    git pull $args
}
function gm
{
    git merge $args
}
function gp
{
    git push $args
}
function gpf
{
    git push --force-with-lease $args
}
function gpf!
{
    git push --force $args
}
function gpoat
{
    git push origin --all
    git push origin --tags
}
function gpr
{
    git pull --rebase $args
}
function gr
{
    git remote $args
}
function gra
{
    git remote add $args
}
function grb
{
    git rebase $args
}
function grba
{
    git rebase --abort $args
}
function grbc
{
    git rebase --continue $args
}
function grbi
{
    git rebase -i $args
}
function grbm
{
    $MainBranch = Get-Git-MainBranch

    git fetch origin $MainBranch
    git rebase origin/$MainBranch $args
}
function grh
{
    git reset $args
}
function grhh
{
    git reset --hard $args
}
