#!/usr/bin/env nix
#! nix shell --inputs-from . nixpkgs#nushell -c nu

use ../update-utils.nu [root_dir]

const appcast = "https://blob.superlogical.com/public/rex-app/preview/appcast.xml"

def main [] {
  let sources_path = root_dir $env.FILE_PWD $env.PWD | path join "sources.json"
  let current_version = open $sources_path | get version

  # from xml drops the sparkle: prefix, so sparkle:version is matched as version.
  let latest = http get --raw $appcast
    | from xml
    | get content
    | where tag == "channel"
    | first
    | get content
    | where tag == "item"
    | each {|item|
      let fields = $item.content
      let text = {|tag| $fields | where tag == $tag | first | get content.0.content }
      {
        build: (do $text "version" | into int)
        short: (do $text "shortVersionString")
        url: ($fields | where tag == "enclosure" | first | get attributes.url)
      }
    }
    | sort-by build
    | last
  let latest_version = $"($latest.short)-($latest.build)"

  print $"Current version: ($current_version)"
  print $"Latest version:  ($latest_version)"

  if $current_version == $latest_version {
    print "Already up to date."
    return
  }

  let hash = nix store prefetch-file --json $latest.url | from json | get hash

  { version: $latest_version, url: $latest.url, hash: $hash }
  | to json --indent 2
  | $"($in)\n"
  | save --force $sources_path

  print $"Updated rex to version ($latest_version)"
}
