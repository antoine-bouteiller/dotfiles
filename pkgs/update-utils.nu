# Shared helpers for checked-in package updater scripts.

# When run as a flake updateScript, FILE_PWD is the read-only /nix/store
# copy — write to the git checkout (CWD = repo root) instead.
export def root_dir [script_dir: string, checkout: string]: nothing -> string {
  if ($script_dir | str starts-with "/nix/store") {
    $checkout | path join "pkgs" ($script_dir | path basename)
  } else {
    $script_dir
  }
}

# Unauthenticated api.github.com allows 60 req/h per IP, which CI runners share.
export def github_headers []: nothing -> list<string> {
  if ($env.GH_TOKEN? | is-not-empty) { [Authorization $"Bearer ($env.GH_TOKEN)"] } else { [] }
}

# `nix hash convert` (modern Nix) and `nix hash to-sri` (Lix, older Nix) both
# produce SRI form.
export def to_sri [checksum: string]: nothing -> string {
  try {
    nix hash convert --hash-algo sha256 --to sri $checksum | str trim
  } catch {
    nix hash to-sri --type sha256 $checksum | str trim
  }
}
