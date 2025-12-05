# Detect which package manager is used based on lockfile and run command
export def detect-pm [...args] {
  let pm = if ('bun.lock' | path exists) {
    'bun'
  } else if ('pnpm-lock.yaml' | path exists) {
    'pnpm'
  } else if ('yarn.lock' | path exists) {
    'yarn'
  } else if ('package-lock.json' | path exists) {
    'npm'
  } else {
    'npm'  # default fallback
  }

  ^$pm ...$args
}

# Package manager command aliases
export alias bd = detect-pm dev
export alias bs = detect-pm start
export alias bl = detect-pm lint
export alias bf = detect-pm format
export alias ts = detect-pm tsgo
