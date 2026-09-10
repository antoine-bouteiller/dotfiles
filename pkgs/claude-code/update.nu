#!/usr/bin/env nix
#! nix shell --inputs-from . nixpkgs#nushell -c nu

use ../update-utils.nu [root_dir to_sri]

const base_url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"
const platforms = {
  "x86_64-linux": "linux-x64"
  "aarch64-linux": "linux-arm64"
  "x86_64-darwin": "darwin-x64"
  "aarch64-darwin": "darwin-arm64"
}

def fetch_latest_version []: nothing -> string {
  http get "https://registry.npmjs.org/@anthropic-ai/claude-code/latest"
  | get version
}

def fetch_manifest [version: string]: nothing -> record {
  http get $"($base_url)/($version)/manifest.json"
}

def get_current_version []: nothing -> string {
  let sources_path = root_dir $env.FILE_PWD $env.PWD | path join "sources.json"
  if ($sources_path | path exists) {
    open $sources_path | get version
  } else {
    ""
  }
}

def main [] {
  let current_version = get_current_version
  let latest_version = fetch_latest_version

  print $"Current version: ($current_version)"
  print $"Latest version:  ($latest_version)"

  if $current_version == $latest_version {
    print "Already up to date."
    return
  }

  print $"Updating claude-code from ($current_version) to ($latest_version)"

  let manifest = fetch_manifest $latest_version

  mut platforms_data = {}
  for platform in ($platforms | transpose nix_platform manifest_platform) {
    let checksum = ($manifest.platforms | get $platform.manifest_platform | get checksum)
    let hash = to_sri $checksum
    let url = $"($base_url)/($latest_version)/($platform.manifest_platform)/claude"
    $platforms_data = $platforms_data | insert $platform.nix_platform {url: $url, hash: $hash}
    print $"  ($platform.nix_platform): ($hash)"
  }

  { version: $latest_version, platforms: $platforms_data }
  | to json --indent 2
  | $"($in)\n"
  | save --force (root_dir $env.FILE_PWD $env.PWD | path join "sources.json")

  print $"Updated claude-code to version ($latest_version)"
}
