#!/bin/sh -e
#
# Fresh NixOS install from the installer ISO, starting with nothing checked out:
#
#   curl -sL https://raw.githubusercontent.com/antoine-bouteiller/dotfiles/main/bootstrap.sh | sh -s -- antoine-dell
#
# Clones this flake, then hands over to .#bootstrap (see apps/x86_64-linux/bootstrap
# for what that does and the post-install steps).

host="$1"
if [ -z "$host" ]; then
  echo "usage: bootstrap.sh <flake-hostname>" >&2
  exit 1
fi

repo="${DOTFILES_REPO:-https://github.com/antoine-bouteiller/dotfiles.git}"
dir="${DOTFILES_DIR:-/tmp/dotfiles}"
# Via the environment rather than a flag, so nested and sudo'd nix calls inherit it.
export NIX_CONFIG="extra-experimental-features = nix-command flakes"

[ -d "$dir" ] || nix run nixpkgs#git -- clone --depth 1 "$repo" "$dir"
cd "$dir"
nix run .#bootstrap -- "$host"
