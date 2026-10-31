# Host age keys: .sops.yaml recipients and re-encryption with the Bitwarden admin key.

# Secure note whose notes hold the admin identity, a recipient of every secret.
const admin_item = 'sops-admin-age-key'

# Under curl | sh, stdin is the script pipe; prompts must read the terminal.
def --wrapped bw [...args: string]: nothing -> string {
  ^sh -c 'exec bw "$@" </dev/tty' -- ...$args | str trim
}

# An explicit SOPS_AGE_KEY or SOPS_AGE_KEY_FILE skips Bitwarden.
def admin-env []: nothing -> record {
  if ($env.SOPS_AGE_KEY? | is-not-empty) or ($env.SOPS_AGE_KEY_FILE? | is-not-empty) {
    return {}
  }
  print $"Fetching the admin age key from Bitwarden item '($admin_item)'..."
  let session = match (bw status | from json | get status) {
    'unauthenticated' => (bw login --raw)
    'locked' => (bw unlock --raw)
    _ => ($env.BW_SESSION? | default '')
  }
  let identities = bw get notes $admin_item --session $session | lines | where {|line| $line | str starts-with 'AGE-SECRET-KEY-' }
  if ($identities | length) != 1 {
    error make {msg: $"Bitwarden item '($admin_item)' must hold exactly one AGE-SECRET-KEY line."}
  }
  {SOPS_AGE_KEY: $identities.0}
}

export def generate-key []: nothing -> record<identity: string, recipient: string> {
  let identity = ^age-keygen | complete | get stdout
  {identity: $identity, recipient: ($identity | ^age-keygen -y | str trim)}
}

export def recipient-from-file [key_file: string]: nothing -> string {
  ^sudo cat $key_file | ^age-keygen -y | lines | first
}

# Recipient of the `&name` anchor, or null when the host is not listed.
export def recipient [config: path, name: string]: nothing -> any {
  let line = open --raw $config | lines | where {|line| $line | str starts-with $"  - &($name) " } | get 0?
  if $line == null { null } else { $line | str trim | split row ' ' | get 2 }
}

# Points the `&name` anchor at the recipient; a new host is appended to the keys and the rule.
def set-recipient [config: path, name: string, value: string] {
  let anchor = $"  - &($name) "
  let lines = open --raw $config | lines
  let updated = if (recipient $config $name) != null {
    $lines | each {|line| if ($line | str starts-with $anchor) { $"($anchor)($value)" } else { $line } }
  } else {
    let last_key = $lines | enumerate | where {|line| $line.item | str starts-with '  - &' } | last | get index
    let last_alias = $lines | enumerate | where {|line| $line.item | str starts-with '      - *' } | last | get index
    $lines | insert ($last_alias + 1) $"      - *($name)" | insert ($last_key + 1) $"($anchor)($value)"
  }
  $updated | str join "\n" | $in + "\n" | save --force $config
}

def secret-files [checkout: path]: nothing -> list<path> {
  ^git -C $checkout ls-files -z -- secrets | split row (char nul) | where {|file| $file != '' } | each {|file| $checkout | path join $file }
}

# Writes the identity root-only, through sudo unless the file is under $HOME.
export def install-key [key_file: string, identity: string] {
  if ($key_file | str starts-with $"($env.HOME)/") {
    mkdir ($key_file | path dirname)
    ^install -m 600 /dev/null $key_file
    $identity | save --force $key_file
  } else {
    ^sudo install -d -m 700 ($key_file | path dirname)
    ^sudo install -m 600 /dev/null $key_file
    $identity | ^sudo tee $key_file out> /dev/null
  }
}

# Sets the host's recipient in the public checkout and in `.private` when it lists the
# host, re-encrypts their tracked secrets, then runs `finish`. Any failure restores the files.
export def reencrypt [root: path, name: string, value: string, finish: closure] {
  let private = $root | path join .private
  let checkouts = [$root] ++ (if (($private | path join .sops.yaml | path exists) and (recipient ($private | path join .sops.yaml) $name) != null) { [$private] } else { [] })
  let sops_env = admin-env
  let backup = $checkouts | each {|checkout| [($checkout | path join .sops.yaml)] ++ (secret-files $checkout) } | flatten | each {|file| {path: $file, data: (open --raw $file)} }
  try {
    for checkout in $checkouts {
      let config = $checkout | path join .sops.yaml
      set-recipient $config $name $value
      for file in (secret-files $checkout) {
        # The host's SOPS_AGE_KEY_CMD fails before its key file exists.
        with-env $sops_env { hide-env --ignore-errors SOPS_AGE_KEY_CMD; ^sops --config $config updatekeys --yes $file }
      }
    }
    do $finish
  } catch {|err|
    for file in $backup { $file.data | save --raw --force $file.path }
    error make {msg: $"Re-encryption failed; restored .sops.yaml and secrets: ($err.msg)"}
  }
  print $"Re-encrypted secrets for ($name): commit .sops.yaml and secrets/ in ($checkouts | str join ', ')."
}
