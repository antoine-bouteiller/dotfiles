#!/usr/bin/env nix
#! nix shell --inputs-from . nixpkgs#nushell -c nu

const base_url = "https://github.com/earendil-works/pi/releases/download"
const platforms = {
  "x86_64-linux": "pi-linux-x64.tar.gz"
  "aarch64-linux": "pi-linux-arm64.tar.gz"
  "aarch64-darwin": "pi-darwin-arm64.tar.gz"
  "x86_64-darwin": "pi-darwin-x64.tar.gz"
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

def fetch_latest_version []: nothing -> string {
  http get "https://api.github.com/repos/earendil-works/pi/releases/latest"
  | get tag_name
  | str trim --left --char "v"
}

def prefetch_hash [url: string]: nothing -> string {
  let hex = nix-prefetch-url --type sha256 $url | lines | last
  nix hash convert --hash-algo sha256 --to sri $hex | str trim
}

def main [] {
  let sources_path = root_dir | path join "sources.json"
  let current_version = open $sources_path | get version
  let latest_version = fetch_latest_version

  print $"Current version: ($current_version)"
  print $"Latest version:  ($latest_version)"

  if $current_version == $latest_version {
    print "Already up to date."
    return
  }

  print $"Updating pi from ($current_version) to ($latest_version)"

  mut platforms_data = {}
  for platform in ($platforms | transpose nix_platform file) {
    let url = $"($base_url)/v($latest_version)/($platform.file)"
    let entry = {url: $url, hash: (prefetch_hash $url)}
    $platforms_data = $platforms_data | insert $platform.nix_platform $entry
    print $"  ($platform.nix_platform): ($entry.hash)"
  }

  { version: $latest_version, platforms: $platforms_data }
  | to json --indent 2
  | $"($in)\n"
  | save --force $sources_path

  print $"Updated pi to version ($latest_version)"
}
