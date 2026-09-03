#!/usr/bin/env nix
#! nix shell --inputs-from . nixpkgs#nushell -c nu

const repo = "akitaonrails/ai-usagebar"
const platforms = {
  "x86_64-linux": "x86_64"
  "aarch64-linux": "aarch64"
}

def root_dir []: nothing -> string {
  # When run as a flake updateScript, FILE_PWD is the read-only /nix/store
  # copy — write to the git checkout (CWD = repo root) instead.
  if ($env.FILE_PWD | str starts-with "/nix/store") {
    $env.PWD | path join "pkgs" ($env.FILE_PWD | path basename)
  } else {
    $env.FILE_PWD
  }
}

def main [] {
  let sources_path = root_dir | path join "sources.json"
  let current_version = open $sources_path | get version
  let latest_tag = http get $"https://api.github.com/repos/($repo)/releases/latest" | get tag_name
  let latest_version = $latest_tag | str replace -r '^v' ''

  print $"Current version: ($current_version)"
  print $"Latest version:  ($latest_version)"

  if $current_version == $latest_version {
    print "Already up to date."
    return
  }

  let base = $"https://github.com/($repo)/releases/download/($latest_tag)"

  mut platforms_data = {}
  for platform in ($platforms | transpose nix_platform arch) {
    let url = $"($base)/ai-usagebar-linux-($platform.arch).tar.gz"
    let hex = http get $"($url).sha256" | decode utf-8 | str trim | split row " " | first
    let hash = nix hash convert --hash-algo sha256 $hex | str trim
    $platforms_data = $platforms_data | insert $platform.nix_platform {url: $url, hash: $hash}
    print $"  ($platform.nix_platform): ($hash)"
  }

  { version: $latest_version, platforms: $platforms_data }
  | to json --indent 2
  | $"($in)\n"
  | save --force $sources_path

  print $"Updated ai-usagebar to version ($latest_version)"
}
