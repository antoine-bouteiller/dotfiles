# Resolve once after boot; apply only from AdGuard's pre-start hook.
def main [] {}

def write-atomic [path: string, content: string, mode: string] {
  let tmp = (^mktemp $"($path).XXXXXX" | str trim)
  $content | save --raw --force $tmp
  ^chmod $mode $tmp
  mv --force $tmp $path
}

def "main resolve" [yaml: string, desired: string, ...domains: string] {
  ^tailscale wait --timeout=60s
  let result = (^timeout 5s tailscale ip -4 | complete)
  let ip = ($result.stdout | str trim)
  if $result.exit_code != 0 or $ip == '' {
    error make {msg: 'No Tailscale IPv4 address; leaving DNS rewrites unchanged'}
  }
  let rewrites = ($domains | each {|domain| {domain: $domain, answer: $ip, enabled: true}})
  let config = (open $yaml)
  if $config.filtering?.rewrites? == $rewrites and ($config.filtering?.rewrites_enabled? | default true) {
    return
  }
  write-atomic $desired ($rewrites | to json) '644'
  ^systemctl --no-block try-restart adguardhome.service
}

def "main apply" [desired: string, yaml: string] {
  if not ($desired | path exists) { return }
  let config = (open $yaml | default {})
  let filtering = (($config.filtering? | default {}) | merge {
    rewrites_enabled: true
    rewrites: (open $desired)
  })
  write-atomic $yaml ($config | upsert filtering $filtering | to yaml) '600'
}
