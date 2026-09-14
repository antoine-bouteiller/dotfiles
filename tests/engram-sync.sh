#!/usr/bin/env bash
# Regression tests for modules/home/applications/agents/engram/sync.nu.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
script="$root/modules/home/applications/agents/engram/sync.nu"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
mkdir -p "$HOME/bin"

cat >"$HOME/bin/engram" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
  'sync --all')
    mkdir -p .engram/chunks
    if [ -f "$ENGRAM_DATA_DIR/payload" ]; then
      id=$(cat "$ENGRAM_DATA_DIR/payload")
      printf '%s\n' "$id" >".engram/chunks/$id"
      printf '{"chunk":"%s"}\n' "$id" >.engram/manifest.json
    fi
    ;;
  'sync --import')
    test -f .engram/manifest.json && cp .engram/manifest.json "$ENGRAM_DATA_DIR/imported"
    ;;
  *) echo "unexpected fake engram arguments: $*" >&2; exit 2 ;;
esac
FAKE
chmod +x "$HOME/bin/engram"
export PATH="$HOME/bin:$PATH"

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_file() { [ -f "$1" ] || fail "missing $1"; }
new_data() { mkdir -p "$1"; }
run() { ENGRAM_DATA_DIR="$1" nu --no-config-file "$script" "$2" "$3"; }

# Empty remote bootstrap, followed by a repeat, must create and retain export.
remote="$tmp/empty.git"; git init --bare --initial-branch=main -q "$remote"
data_a="$tmp/data-a"; repo_a="$tmp/a"; new_data "$data_a"; echo alpha >"$data_a/payload"
run "$data_a" "$remote" "$repo_a"
git --git-dir="$remote" show main:.engram/chunks/alpha >/dev/null || fail 'bootstrap was not pushed'
mkdir "$repo_a/.engram-sync.lock"
if run "$data_a" "$remote" "$repo_a"; then fail 'lock contention unexpectedly succeeded'; fi
[ -d "$repo_a/.engram-sync.lock" ] || fail 'contended lock was deleted'
rmdir "$repo_a/.engram-sync.lock"

empty_remote="$tmp/noop.git"; git init --bare --initial-branch=main -q "$empty_remote"
empty_data="$tmp/data-empty"; new_data "$empty_data"
run "$empty_data" "$empty_remote" "$tmp/empty"
if git --git-dir="$empty_remote" show-ref --quiet; then fail 'empty sync created a remote ref'; fi
[ ! -e "$empty_data/imported" ] || fail 'empty sync imported a missing manifest'
absent_remote="$tmp/absent.git"; git init --bare --initial-branch=main -q "$absent_remote"
run "$tmp/data-absent" "$absent_remote" "$tmp/absent"
if git --git-dir="$absent_remote" show-ref --quiet; then fail 'absent data directory created a remote ref'; fi
[ ! -e "$tmp/absent" ] || fail 'absent data directory created a checkout'
head_before=$(git -C "$repo_a" rev-parse HEAD)
run "$data_a" "$remote" "$repo_a"
[ "$(git -C "$repo_a" rev-parse HEAD)" = "$head_before" ] || fail 'repeat created a commit'

# An existing remote can be imported by a checkout that has no local export.
data_b="$tmp/data-b"; repo_b="$tmp/b"; new_data "$data_b"
run "$data_b" "$remote" "$repo_b"
assert_file "$data_b/imported"
grep -q alpha "$data_b/imported" || fail 'existing remote was not imported'

# Concurrent clients with incompatible manifest edits stop at a merge conflict
# and leave the second client's local commit and merge state intact.
git clone -q "$remote" "$tmp/c1"; git clone -q "$remote" "$tmp/c2"
git -C "$tmp/c1" config commit.gpgsign true
data_c1="$tmp/data-c1"; data_c2="$tmp/data-c2"; new_data "$data_c1"; new_data "$data_c2"
echo one >"$data_c1/payload"; echo two >"$data_c2/payload"
run "$data_c1" "$remote" "$tmp/c1"
if run "$data_c2" "$remote" "$tmp/c2"; then fail 'divergent manifests unexpectedly merged'; fi
git -C "$tmp/c2" rev-parse -q --verify MERGE_HEAD >/dev/null || fail 'conflict state was discarded'
[ "$(git -C "$tmp/c2" log -1 --format=%s)" = 'engram: sync memories' ] || fail 'local commit was lost'
if run "$data_c2" "$remote" "$tmp/c2"; then fail 'conflicted checkout was reused'; fi
git -C "$tmp/c2" rev-parse -q --verify MERGE_HEAD >/dev/null || fail 'second run altered conflict state'

# A rejected push retains the successfully created local export commit.
blocked="$tmp/blocked.git"; git init --bare --initial-branch=main -q "$blocked"
cat >"$blocked/hooks/pre-receive" <<'HOOK'
#!/bin/sh
exit 1
HOOK
chmod +x "$blocked/hooks/pre-receive"
data_d="$tmp/data-d"; repo_d="$tmp/d"; new_data "$data_d"; echo retained >"$data_d/payload"
if run "$data_d" "$blocked" "$repo_d"; then fail 'rejected push unexpectedly succeeded'; fi
[ "$(git -C "$repo_d" log -1 --format=%s)" = 'engram: sync memories' ] || fail 'failed push lost local commit'
[ ! -e "$repo_d/.engram-sync.lock" ] || fail 'failed push left its lock behind'
rm "$blocked/hooks/pre-receive"
run "$data_d" "$blocked" "$repo_d"
git --git-dir="$blocked" show main:.engram/chunks/retained >/dev/null || fail 'retry did not push preserved commit'

printf '\n' >>"$repo_a/.engram/manifest.json"
cp "$repo_a/.engram/manifest.json" "$tmp/dirty-manifest"
if run "$data_a" "$remote" "$repo_a"; then fail 'uncommitted changes were overwritten'; fi
cmp "$repo_a/.engram/manifest.json" "$tmp/dirty-manifest" || fail 'dirty manifest changed'
git -C "$repo_a" add .engram/manifest.json
if run "$data_a" "$remote" "$repo_a"; then fail 'staged changes were committed'; fi
git -C "$repo_a" diff --cached --quiet && fail 'staged change was lost'

echo 'engram-sync tests: ok'
