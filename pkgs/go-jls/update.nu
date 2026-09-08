#!/usr/bin/env nix
#! nix shell --inputs-from . nixpkgs#nushell nixpkgs#nix-update -c nu

# go-jls has no tagged releases yet; track the tip of main.
def main [] {
  ^nix-update --flake go-jls --version=branch
}
