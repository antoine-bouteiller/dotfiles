#!/usr/bin/env nix
#! nix shell --inputs-from . nixpkgs#nushell -c nu

use ../update-utils.nu [root_dir github_headers]

const repo = "lightpanda-io/browser"
const platforms = {
  "x86_64-linux": "x86_64-linux"
  "aarch64-linux": "aarch64-linux"
  "aarch64-darwin": "aarch64-macos"
}

def main [] {
  let sources_path = root_dir $env.FILE_PWD $env.PWD | path join "sources.json"
  let current_version = open $sources_path | get version
  # `releases/latest` resolves to the mutable `nightly` tag.
  let latest_tag = http get -H (github_headers) $"https://api.github.com/repos/($repo)/releases"
    | where {|r| not $r.prerelease and not $r.draft and ($r.tag_name =~ '^v?\d') }
    | first
    | get tag_name
  let latest_version = $latest_tag | str replace -r '^v' ''

  print $"Current version: ($current_version)"
  print $"Latest version:  ($latest_version)"

  if $current_version == $latest_version {
    print "Already up to date."
    return
  }

  let base = $"https://github.com/($repo)/releases/download/($latest_tag)"

  # Releases publish no checksums.
  mut platforms_data = {}
  for platform in ($platforms | transpose nix_platform target) {
    let url = $"($base)/lightpanda-($platform.target)"
    let hash = nix store prefetch-file --json $url | from json | get hash
    $platforms_data = $platforms_data | insert $platform.nix_platform {url: $url, hash: $hash}
    print $"  ($platform.nix_platform): ($hash)"
  }

  { version: $latest_version, platforms: $platforms_data }
  | to json --indent 2
  | $"($in)\n"
  | save --force $sources_path

  print $"Updated lightpanda to version ($latest_version)"
}
