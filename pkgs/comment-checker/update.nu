#!/usr/bin/env nix
#! nix shell --inputs-from . nixpkgs#nushell nixpkgs#nix-update -c nu

use ../update-utils.nu [root_dir github_headers]

const owner_repo = "code-yeongyu/go-claude-code-comment-checker"

# The tree-sitter-language-pack release we must pre-fetch is whatever version
# comment-checker pins in its Cargo.lock — read it straight from the tag so the
# parser bundle can never drift away from the crate that consumes it.
def tslp_version [pkg_version: string]: nothing -> string {
  let headers = github_headers
  http get -H $headers $"https://raw.githubusercontent.com/($owner_repo)/v($pkg_version)/Cargo.lock"
  | split row "[[package]]"
  | where {|block| $block =~ '(?m)^name = "tree-sitter-language-pack"$'}
  | first
  | parse --regex '(?m)^version = "(?<v>[^"]+)"$'
  | get v.0
}

def replace_line [file: string, key: string, value: string] {
  open --raw $file
  | str replace --regex $'($key) = "[^"]*";' $'($key) = "($value)";'
  | save --force $file
}

def main [] {
  # Bump version + src hash + cargoHash for the GitHub release.
  ^nix-update --flake comment-checker

  let default_nix = root_dir $env.FILE_PWD $env.PWD | path join "default.nix"
  let pkg_version = (^nix eval --raw ".#comment-checker.version")
  let tslp = (tslp_version $pkg_version)
  print $"comment-checker ($pkg_version) pins tree-sitter-language-pack v($tslp)"

  # Re-fetch the parser bundle for that exact tslp version and record its hash.
  let url = $"https://github.com/kreuzberg-dev/tree-sitter-language-pack/releases/download/v($tslp)/parser-sources-($tslp).tar.zst"
  let hash = (
    ^nix store prefetch-file --json --name $"parser-sources-($tslp).tar.zst" $url
    | from json
    | get hash
  )

  replace_line $default_nix "tslpVersion" $tslp
  replace_line $default_nix "parserSourcesHash" $hash
  print $"Pinned parser bundle v($tslp): ($hash)"
}
