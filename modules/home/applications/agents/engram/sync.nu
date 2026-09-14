# Synchronize only Engram's git-friendly export, never its database or config.
def fail [message: string] {
  print --stderr $message
  error make {msg: $message}
}

def main [...args: string] {
  if ($args | length) != 2 { print --stderr 'usage: engram-sync.nu <remote> <dedicated-checkout>'; exit 64 }
  let remote = $args.0
  let repo = $args.1
  let data_dir = ($env.ENGRAM_DATA_DIR? | default ($env.HOME | path join '.engram'))
  if not ($data_dir | path exists) or (($data_dir | path type) != 'dir') {
    # Engram has not been initialized yet; periodic sync is intentionally a no-op.
    return
  }

  $env.ENGRAM_DATA_DIR = $data_dir
  $env.GIT_TERMINAL_PROMPT = '0'
  $env.GIT_MERGE_AUTOEDIT = 'no'
  $env.GIT_SSH_COMMAND = 'ssh -o BatchMode=yes'

  mkdir $repo
  cd $repo
  if not ('.git' | path exists) {
    let init_result = (^git init -b main | complete)
    if $init_result.exit_code != 0 { fail 'could not initialize dedicated checkout' }
  }
  let worktree_result = (^git rev-parse --is-inside-work-tree | complete)
  if $worktree_result.exit_code != 0 or ($worktree_result.stdout | str trim) != 'true' { fail $'not a git checkout: ($repo)' }

  let lock = '.engram-sync.lock'
  let lock_result = (^mkdir $lock | complete)
  if $lock_result.exit_code != 0 {
    print --stderr $'Engram sync is already running, or has a stale lock: ($repo)/($lock); remove it only after confirming no sync is running'
    exit 1
  }
  let outcome = (try { sync $remote $repo $lock; {ok: true} } catch { {ok: false} } finally { rm -rf $lock })
  if not $outcome.ok { exit 1 }
}

def sync [remote: string, repo: string, lock: string] {
  ($nu.pid | into string) | save --force ($lock | path join 'pid')

  let git_dir = (^git rev-parse --git-dir | str trim)
  if ((^git rev-parse -q --verify MERGE_HEAD | complete).exit_code == 0) or (($git_dir | path join 'rebase-merge') | path exists) or (($git_dir | path join 'rebase-apply') | path exists) or not ((^git diff --name-only --diff-filter=U | str trim) | is-empty) {
    fail 'refusing sync: checkout has an unfinished merge, rebase, or unmerged files'
  }
  let staged_result = (^git diff --cached --quiet -- | complete)
  if $staged_result.exit_code != 0 { fail 'refusing sync: checkout has staged changes' }
  let dirty_result = (^git diff --quiet -- | complete)
  if $dirty_result.exit_code != 0 { fail 'refusing sync: checkout has uncommitted changes' }

  let remote_result = (^git remote get-url engram-sync | complete)
  if $remote_result.exit_code == 0 {
    if (($remote_result.stdout | str trim) != $remote) { fail "checkout's engram-sync remote differs from requested remote" }
  } else {
    let add_remote_result = (^git remote add engram-sync $remote | complete)
    if $add_remote_result.exit_code != 0 { fail 'could not add engram-sync remote' }
  }

  let export_result = (^engram sync --all | complete)
  if $export_result.exit_code != 0 { fail 'Engram export failed' }
  mut sync_paths = []
  if ('.engram/manifest.json' | path exists) { $sync_paths = ($sync_paths | append '.engram/manifest.json') }
  if ('.engram/chunks' | path exists) { $sync_paths = ($sync_paths | append '.engram/chunks') }
  if not ($sync_paths | is-empty) {
    let add_result = (^git add -A -- ...$sync_paths | complete)
    if $add_result.exit_code != 0 { fail 'could not stage Engram export' }
    let diff_result = (^git diff --cached --quiet -- ...$sync_paths | complete)
    if $diff_result.exit_code != 0 {
      let name_result = (^git config user.name | complete)
      if $name_result.exit_code != 0 { ^git config user.name 'Engram Sync' }
      let email_result = (^git config user.email | complete)
      if $email_result.exit_code != 0 { ^git config user.email 'engram-sync@localhost' }
      let commit_result = (^git -c commit.gpgSign=false commit --only -m 'engram: sync memories' -- ...$sync_paths | complete)
      if $commit_result.exit_code != 0 { fail 'could not commit Engram export' }
    }
  }

  let fetch_result = (^git fetch engram-sync '+refs/heads/*:refs/remotes/engram-sync/*' | complete)
  if $fetch_result.exit_code != 0 { fail 'could not fetch Engram remote' }
  let head = (^git ls-remote --symref engram-sync HEAD | complete)
  if $head.exit_code != 0 { fail 'could not determine Engram remote branch' }
  let head_line = ($head.stdout | lines | where {|line| $line | str starts-with 'ref: refs/heads/' } | get -o 0 | default '')
  let branch = if ($head_line | is-empty) { 'main' } else { $head_line | split row (char tab) | first | str replace 'ref: refs/heads/' '' }

  let ref_result = (^git show-ref --verify --quiet $'refs/remotes/engram-sync/($branch)' | complete)
  let local_head = (^git rev-parse --verify HEAD | complete)
  if $ref_result.exit_code == 0 {
    if $local_head.exit_code != 0 {
      let checkout_result = (^git checkout -B $branch $'engram-sync/($branch)' | complete)
      if $checkout_result.exit_code != 0 { fail 'could not check out Engram remote branch' }
    } else {
      let merge_result = (^git -c commit.gpgSign=false merge --allow-unrelated-histories --no-edit $'engram-sync/($branch)' | complete)
      if $merge_result.exit_code != 0 { fail $'Engram sync stopped: resolve the git merge conflict in ($repo); no state was reset.' }
    }
  } else if $local_head.exit_code != 0 {
    return
  }

  let import_result = (^engram sync --import | complete)
  if $import_result.exit_code != 0 { fail 'Engram import failed' }
  let push_result = (^git push engram-sync $'HEAD:refs/heads/($branch)' | complete)
  if $push_result.exit_code != 0 { fail 'could not push Engram export; local commit was preserved' }
}
