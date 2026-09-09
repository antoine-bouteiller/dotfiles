#!/bin/sh
# Sonarr's custom dataDir is provisioned by a non-destructive tmpfiles `d` rule (AC-004).
# Exercises real systemd-tmpfiles against a throwaway --root tree; Linux only.
set -eu
rule="d /var/lib/sonarr 0775 sonarr media - -"
if [ "$(uname)" != Linux ] || ! command -v systemd-tmpfiles >/dev/null; then
  echo "review-fixes-sonarr: UNRUN (needs Linux systemd-tmpfiles); evaluate the rule with:"
  echo "  nix eval --json .#nixosConfigurations.plex-server.config.systemd.tmpfiles.rules | jq -e '.[] | select(. == \"$rule\")'"
  exit 0
fi
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
mkdir -p "$root/etc" "$root/usr/lib/tmpfiles.d"
# Map the fixture's sonarr/media names onto the invoking uid/gid so no root is needed.
printf 'sonarr:x:%s:%s::/var/lib/sonarr:/bin/sh\n' "$(id -u)" "$(id -g)" > "$root/etc/passwd"
printf 'media:x:%s:\n' "$(id -g)" > "$root/etc/group"
echo "$rule" > "$root/usr/lib/tmpfiles.d/sonarr.conf"

expect_state() {
  got=$(stat -c '%u:%g %a' "$root/var/lib/sonarr")
  [ "$got" = "$(id -u):$(id -g) 775" ] || { echo "FAIL $1: $got"; exit 1; }
}
systemd-tmpfiles --root="$root" --create
expect_state fresh
echo keep > "$root/var/lib/sonarr/sonarr.db"
systemd-tmpfiles --root="$root" --create
systemd-tmpfiles --root="$root" --create
expect_state existing
[ "$(cat "$root/var/lib/sonarr/sonarr.db")" = keep ] || { echo "FAIL existing content lost"; exit 1; }
echo "review-fixes-sonarr: PASS"
