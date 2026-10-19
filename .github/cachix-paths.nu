def --wrapped checked [command: string, ...args: string]: any -> string {
  let result = ($in | ^$command ...$args | complete)
  if $result.exit_code != 0 {
    error make {msg: $result.stderr}
  }
  $result.stdout
}

def main [before_file: path, names_file: path] {
  let before = (open --raw $before_file | lines)
  # These nixpkgs packages are not reliably covered by provenance discovery.
  let names = (open $names_file | append [nvidia plex-desktop plexmediaserver bun] | uniq)
  let store = (checked nix path-info --all --json | from json
    | transpose path info | each {|row| $row.info | upsert path $row.path })
  let paths = ($store | get path)
  # pname covers host overrides and appimageTools' extraction/FHS helpers too.
  let binaries = ($paths | where {|path|
    let name = ($path | path basename | str substring 33.. | str replace -r '\.drv$' '')
    $names | any {|pname| $name == $pname or ($name | str starts-with $"($pname)-") }
  })
  # Home Manager's text files and assembled file tree are cheap local builds.
  # rust-overlay toolchain components end in a target triple and only repackage
  # upstream binaries. Crane's `-deps-` artifacts are build-only caches.
  let cheap = '(\.tgz$|-bun-pkg-|-bun-cache$|-vendor$|-vendor-staging$|-zig-cache$|-hm_|-home-manager-files$|-(x86_64|aarch64)-(unknown|apple)-[a-z0-9_-]+$|-deps-[0-9][^/]*$)'
  # Fixed-output paths are fetched sources and archives that clients can refetch.
  let fetched = ($store | where {|info|
    let ca = ($info.ca? | default '')
    if ($ca | describe) == 'string' { $ca starts-with 'fixed:' } else { $ca.method != 'text' }
  } | get path)
  let excluded = ($binaries | append ($paths | where {|path| $path =~ $cheap }) | append $fetched | uniq)

  # Cachix pushes closures. Exclude transitive referrers too, batching roots to
  # stay below macOS's argument-size limit. Only query realized store paths.
  let blocked = ($excluded | where {|path| $path in $paths } | chunks 128
    | each {|roots| checked nix-store --query --referrers-closure ...$roots | lines }
    | flatten | uniq)
  let selected = ($store | where {|info|
    ($info.path not-in $before and $info.path not-in $blocked
      and not ($info.path | str ends-with '.drv')
      and ($info.signatures? | default [] | is-empty))
  } | get path | sort)
  print --stderr $"Cachix: selected ($selected | length) new paths; excluded ($blocked | length) paths and referrers"
  for path in $selected { print $path }
}
