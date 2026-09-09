#!/bin/sh
# The updaters' sri_hash helper must work on modern Nix (`nix hash convert`),
# fall back on Lix (`nix hash to-sri`), and fail loudly when both fail (AC-003).
# Run under the installed nix, then under pinned modern Nix:
#   nix shell --inputs-from . nixpkgs#nix -c sh tests/review-fixes-update-hash.sh
set -eu
cd "$(dirname "$0")/.."
scripts="pkgs/ai-usagebar/update.nu pkgs/fff-mcp/update.nu pkgs/pi/update.nu"
hex=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
base32=0mdqa9w1p6cmli6976v4wi0sw9r4p5prkj7lzfd1877wk11c9c73
sri=sha256-47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/bin"
cat > "$tmp/bin/nix" <<'MOCK'
#!/bin/sh
# MOCK_NIX=convert: only `hash convert` works; to-sri: only `hash to-sri`; fail: neither.
case "$MOCK_NIX:$1 $2" in
  convert:"hash convert" | to-sri:"hash to-sri") echo "$MOCK_SRI" ;;
  *) echo "mock nix: unsupported $*" >&2; exit 1 ;;
esac
MOCK
chmod +x "$tmp/bin/nix"
export MOCK_SRI="$sri"

fail=0
# helper script input -> stdout of the extracted helper
helper() { nu -c "source $1; sri_hash $2" 2>/dev/null; }
expect() { # label expected script input
  got=$(helper "$3" "$4") || got="<exit $?>"
  [ "$got" = "$2" ] || { echo "FAIL $1 $3 ($4): got '$got'"; return 1; }
}

for s in $scripts; do
  grep -q 'sri_hash \$hex' "$s" || { echo "FAIL $s does not call sri_hash"; fail=1; }
  grep -qE '^\s+nix hash convert' "$s" && grep -qE '^\s+nix hash to-sri' "$s" \
    || { echo "FAIL $s lacks the Nix/Lix fallback"; fail=1; }

  for input in "$hex" "$base32"; do
    # Real installed nix, fixture only: no downloads, no manifest writes.
    expect "real-nix" "$sri" "$s" "$input" || fail=1
    (export PATH="$tmp/bin:$PATH" MOCK_NIX=convert; expect "mock-modern" "$sri" "$s" "$input") || fail=1
    (export PATH="$tmp/bin:$PATH" MOCK_NIX=to-sri; expect "mock-lix" "$sri" "$s" "$input") || fail=1
  done
  if (export PATH="$tmp/bin:$PATH" MOCK_NIX=fail; helper "$s" "$hex" >/dev/null 2>&1); then
    echo "FAIL $s: both commands failing did not propagate"; fail=1
  fi
done
[ "$fail" -eq 0 ] && echo "review-fixes-update-hash: PASS ($(nix --version | head -1))"
exit "$fail"
