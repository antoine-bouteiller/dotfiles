#!/usr/bin/env nix
#! nix shell --inputs-from . nixpkgs#nushell -c nu

use ../update-utils.nu [root_dir github_headers]

const repo = "oven-sh/bun"
# Keep in sync with the assets nixpkgs' bun selects per platform.
const platforms = {
  "aarch64-darwin": "bun-darwin-aarch64"
  "aarch64-linux": "bun-linux-aarch64"
  "x86_64-linux": "bun-linux-x64-baseline"
}

def main [] {
  let sources_path = root_dir $env.FILE_PWD $env.PWD | path join "sources.json"
  let current_version = open $sources_path | get version
  let latest_tag = http get -H (github_headers) $"https://api.github.com/repos/($repo)/releases/latest"
    | get tag_name
  let latest_version = $latest_tag | str replace -r '^bun-v' ''

  print $"Current version: ($current_version)"
  print $"Latest version:  ($latest_version)"

  if $current_version == $latest_version {
    print "Already up to date."
    return
  }

  let base = $"https://github.com/($repo)/releases/download/($latest_tag)"

  mut platforms_data = {}
  for platform in ($platforms | transpose nix_platform asset) {
    let url = $"($base)/($platform.asset).zip"
    let hash = nix store prefetch-file --json $url | from json | get hash
    $platforms_data = $platforms_data | insert $platform.nix_platform {url: $url, hash: $hash}
    print $"  ($platform.nix_platform): ($hash)"
  }

  { version: $latest_version, platforms: $platforms_data }
  | to json --indent 2
  | $"($in)\n"
  | save --force $sources_path

  print $"Updated bun to version ($latest_version)"
}
