#!/bin/sh
# Both apply wrappers must forward every argument to nh unchanged (AC-001).
set -eu
cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/bin"
cat > "$tmp/bin/nh" <<'MOCK'
#!/bin/sh
printf '%s\n' "$@" > "$MOCK_ARGV"
exit "${MOCK_STATUS:-0}"
MOCK
chmod +x "$tmp/bin/nh"
export PATH="$tmp/bin:$PATH" MOCK_ARGV="$tmp/argv"

fail=0
check() { # wrapper verb args...
  wrapper=$1 verb=$2; shift 2
  MOCK_STATUS=0 "apps/$wrapper/apply" "$@" > /dev/null
  printf '%s\n' "$verb" switch . --impure "$@" > "$tmp/expected"
  if ! cmp -s "$tmp/expected" "$tmp/argv"; then
    echo "FAIL $wrapper $*"; diff "$tmp/expected" "$tmp/argv" || true; fail=1
  fi
}
for case in "x86_64-linux os" "aarch64-darwin darwin"; do
  set -- $case
  check "$1" "$2"
  check "$1" "$2" --dry
  check "$1" "$2" --ask
  check "$1" "$2" --dry --ask
  check "$1" "$2" --dry "arg with spaces"
  if out=$(MOCK_STATUS=3 "apps/$1/apply" --dry 2>&1); then
    echo "FAIL $1: mock failure not propagated"; fail=1
  elif echo "$out" | grep -q complete; then
    echo "FAIL $1: completion message printed after failure"; fail=1
  fi
done
[ "$fail" -eq 0 ] && echo "review-fixes-apply: PASS"
exit "$fail"
