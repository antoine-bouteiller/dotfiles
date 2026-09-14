#!/usr/bin/env nix
#! nix shell --inputs-from . nixpkgs#nushell -c nu

use ../update-utils.nu [root_dir github_headers to_sri]

const repo = "Gentleman-Programming/engram"
const platforms = {
  "aarch64-darwin": "darwin_arm64"
  "x86_64-linux": "linux_amd64"
}

def main [] {
  let sources_path = root_dir $env.FILE_PWD $env.PWD | path join "sources.json"
  let current_version = open $sources_path | get version
  let release = http get -H (github_headers) $"https://api.github.com/repos/($repo)/releases/latest"
  let latest_tag = $release.tag_name
  let latest_version = $latest_tag | str replace -r '^v' ''

  print $"Current version: ($current_version)"
  print $"Latest version:  ($latest_version)"

  if $current_version == $latest_version {
    print "Already up to date."
    return
  }

  let checksums_url = $release.assets
    | where name == "checksums.txt"
    | get browser_download_url
    | first
  let checksums = http get $checksums_url | decode utf-8

  let base = $"https://github.com/($repo)/releases/download/($latest_tag)"
  mut platforms_data = {}
  for platform in ($platforms | transpose nix_platform target) {
    let filename = $"engram_($latest_version)_($platform.target).tar.gz"
    let hex = $checksums
      | lines
      | where {|line| $line | str contains $filename }
      | first
      | split row " "
      | first
    let hash = to_sri $hex
    let url = $"($base)/($filename)"
    $platforms_data = $platforms_data | insert $platform.nix_platform {url: $url, hash: $hash}
    print $"  ($platform.nix_platform): ($hash)"
  }

  let source_hash = nix store prefetch-file --unpack --json $"https://github.com/($repo)/archive/refs/tags/($latest_tag).tar.gz"
    | from json
    | get hash

  { version: $latest_version, sourceHash: $source_hash, platforms: $platforms_data }
  | to json --indent 2
  | $"($in)\n"
  | save --force $sources_path

  print $"Updated engram to version ($latest_version)"
}
