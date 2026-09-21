def --wrapped checked [command: string, ...args: string]: any -> string {
  let result = ($in | ^$command ...$args | complete)
  if $result.exit_code != 0 {
    error make {msg: $result.stderr}
  }
  $result.stdout
}

def main [before_file: path, names_file: path] {
  let before = (open --raw $before_file | lines)
  let names = (open $names_file)
  let raw = (checked nix path-info --all --json | from json)
  # Lix/older Nix returns a list; current Nix returns a path-keyed object.
  let store = if ($raw | describe) starts-with 'record' {
    $raw | transpose path info | each {|row| $row.info | upsert path $row.path }
  } else { $raw }
  let paths = ($store | get path)
  # pname covers host overrides and appimageTools' extraction/FHS helpers too.
  let binaries = ($paths | where {|path|
    let name = ($path | path basename | str substring 33.. | str replace -r '\.drv$' '')
    $names | any {|pname| $name == $pname or ($name | str starts-with $"($pname)-") }
  })
  let cheap = '(\.tgz$|-bun-pkg-|-bun-cache$|-vendor$|-vendor-staging$|-zig-cache$)'
  mut excluded = ($binaries | append ($paths | where {|path| $path =~ $cheap }) | uniq)

  # Inspect direct fixed-output inputs to find hidden fetchurl bindings without
  # excluding the compiled toolchain and libraries used to wrap the binaries.
  let drvs = ($binaries | where {|path| $path | str ends-with '.drv' })
  if ($drvs | is-not-empty) {
    let packages = ($drvs | str join (char nl) | checked nix derivation show --stdin | from json)
    let inputs = ($packages | values | each {|drv| $drv.inputDrvs | columns } | flatten | uniq)
    if ($inputs | is-not-empty) {
      let dependencies = ($inputs | str join (char nl) | checked nix derivation show --stdin | from json)
      let sources = ($dependencies | values | each {|drv| $drv.outputs | values } | flatten
        | where {|output| 'hash' in $output } | get path)
      $excluded = ($excluded | append $sources | uniq)
    }
  }

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
