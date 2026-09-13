#!/usr/bin/env bash

private_config_die() {
  printf 'private configuration error: %s\n' "$*" >&2
  return 1
}

private_config_git_ref() {
  local encoded
  encoded=$(private_config_url_escape "$1")
  printf 'git+file://%s' "${encoded//%2F//}"
}

private_config_checkout_init() {
  local private_root git_root

  if ! PRIVATE_CONFIG_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
    private_config_die 'run this command from a Git checkout'
    return 1
  fi
  PRIVATE_CONFIG_NIX_ARGS=(--no-write-lock-file)
  private_root="$PRIVATE_CONFIG_REPO_ROOT/.private"

  if [ ! -e "$private_root" ] && [ ! -L "$private_root" ]; then
    return 0
  fi
  if [ -L "$private_root" ]; then
    private_config_die '.private must not be a symlink'
    return 1
  fi
  if [ ! -d "$private_root" ] ||
    ! git_root=$(git -C "$private_root" rev-parse --show-toplevel 2>/dev/null) ||
    [ "$(cd "$private_root" && pwd -P)" != "$(cd "$git_root" && pwd -P)" ]; then
    private_config_die '.private must be an independent Git repository'
    return 1
  fi
}

private_config_init() {
  local private_root entry
  private_config_checkout_init || return 1
  PRIVATE_CONFIG_PUBLIC_REF=$(private_config_git_ref "$PRIVATE_CONFIG_REPO_ROOT")
  private_root="$PRIVATE_CONFIG_REPO_ROOT/.private"
  [ -d "$private_root" ] || return 0

  for entry in default.nix home.nix; do
    if [ -e "$private_root/$entry" ] && ! git -C "$private_root" ls-files --error-unmatch -- "$entry" >/dev/null 2>&1; then
      private_config_die ".private/$entry exists but is not tracked; stage it before applying"
      return 1
    fi
  done
  PRIVATE_CONFIG_NIX_ARGS+=(--override-input privateConfig "$(private_config_git_ref "$private_root")")
}

private_config_url_escape() {
  local value=$1 char encoded= i
  local LC_ALL=C
  for ((i = 0; i < ${#value}; i++)); do
    char=${value:i:1}
    case "$char" in
      [a-zA-Z0-9._~-]) encoded+=$char ;;
      *) printf -v encoded '%s%%%02X' "$encoded" "'$char" ;;
    esac
  done
  printf '%s' "$encoded"
}

private_config_normalize_remote_url() {
  local url=$1 host path scheme authority port= port_suffix=
  case "$url" in
    git@*:* )
      host=${url#git@}; host=${host%%:*}; path=${url#*:}; scheme=ssh ;;
    ssh://git@*/* )
      authority=${url#ssh://git@}; authority=${authority%%/*}; path=${url#ssh://git@*/}; scheme=ssh ;;
    https://*/* )
      authority=${url#https://}; authority=${authority%%/*}; path=${url#https://*/}; scheme=https ;;
    *) private_config_die 'private origin must use git@host:path, ssh://git@host/path, or https://host/path'; return 1 ;;
  esac
  if [[ -n ${authority:-} ]]; then
    if [[ $authority == *:* ]]; then
      host=${authority%%:*}
      port=${authority#*:}
      [[ ${#port} -le 5 && $port =~ ^[0-9]+$ ]] && ((10#$port >= 1 && 10#$port <= 65535)) \
        || { private_config_die 'private origin port is malformed or unsafe'; return 1; }
      port_suffix=:$port
    else
      host=$authority
    fi
  fi
  [[ $host =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$ && $path =~ ^[A-Za-z0-9._~/-]+$ ]] \
    || { private_config_die 'private origin is malformed or unsafe'; return 1; }
  printf 'git+%s://%s%s%s' "$scheme" "$([ "$scheme" = ssh ] && printf 'git@')$host" "$port_suffix" "/$path"
}

# Select a remote-safe, immutable privateConfig input, never a local working tree.
private_config_remote_init() {
  local private_root branch revision origin remote_revision normalized public_revision
  PRIVATE_CONFIG_REMOTE_OVERRIDE=
  if ! public_revision=$(git ls-remote --exit-code git@github.com:antoine-bouteiller/dotfiles.git refs/heads/main | awk 'NR == 1 { print $1 }') ||
    ! [[ $public_revision =~ ^[0-9a-fA-F]{40}$ ]]; then
    private_config_die 'public main revision is not advertised by origin'
    return 1
  fi
  PRIVATE_CONFIG_PUBLIC_REF="git+ssh://git@github.com/antoine-bouteiller/dotfiles?ref=main&rev=$public_revision"
  private_config_checkout_init || return 1
  private_root="$PRIVATE_CONFIG_REPO_ROOT/.private"
  [ -d "$private_root" ] || return 0
  [ -z "$(git -C "$private_root" status --porcelain --untracked-files=all)" ] || {
    private_config_die 'private checkout must be clean (including staged and untracked files)'; return 1; }
  if ! branch=$(git -C "$private_root" symbolic-ref --quiet --short HEAD) ||
    ! revision=$(git -C "$private_root" rev-parse HEAD) ||
    ! origin=$(git -C "$private_root" remote get-url origin); then
    private_config_die 'private checkout must have a branch, HEAD, and origin'
    return 1
  fi
  [[ $revision =~ ^[0-9a-fA-F]{40}$ ]] || { private_config_die 'private HEAD is not a full revision'; return 1; }
  normalized=$(private_config_normalize_remote_url "$origin") || return 1
  # Conservative publication check: deploy only when origin's branch tip is this HEAD.
  # This deliberately refuses a local commit that has not been pushed.
  remote_revision=$(git -C "$private_root" ls-remote --exit-code origin "refs/heads/$branch" | awk 'NR == 1 { print $1 }') || {
    private_config_die 'private branch is not advertised by origin'; return 1; }
  [ "$remote_revision" = "$revision" ] || { private_config_die 'private origin branch does not match local HEAD'; return 1; }
  PRIVATE_CONFIG_REMOTE_OVERRIDE="${normalized}?ref=$(private_config_url_escape "$branch")&rev=$revision"
  PRIVATE_CONFIG_NIX_ARGS+=(--override-input privateConfig "$PRIVATE_CONFIG_REMOTE_OVERRIDE")
}

# Flake attrs are short host names, unlike network-discoverable hostnames.
# host_attr nixos|darwin -> the attr whose networking.hostName is this machine.
host_attr() {
  local validation
  case "$1" in
    darwin) validation='cfg.system.drvPath' ;;
    nixos) validation='cfg.config.system.build.toplevel.drvPath' ;;
    *) printf 'unknown configuration kind: %s\n' "$1" >&2; return 1 ;;
  esac
  nix eval --raw "$PRIVATE_CONFIG_PUBLIC_REF#${1}Configurations" --apply \
    "cfgs: let name = builtins.head (builtins.filter (n: cfgs.\${n}.config.networking.hostName == \"$(hostname -s)\") (builtins.attrNames cfgs)); cfg = cfgs.\${name}; in builtins.seq (${validation}) name" \
    "${PRIVATE_CONFIG_NIX_ARGS[@]}"
}

private_config_split_nh_args() {
  local after_separator=0 arg
  PRIVATE_CONFIG_NH_ARGS=()
  PRIVATE_CONFIG_CALLER_NIX_ARGS=()
  for arg in "$@"; do
    if [ "$after_separator" -eq 0 ] && [ "$arg" = -- ]; then
      after_separator=1
    elif [ "$after_separator" -eq 0 ]; then
      PRIVATE_CONFIG_NH_ARGS+=("$arg")
    else
      PRIVATE_CONFIG_CALLER_NIX_ARGS+=("$arg")
    fi
  done
}
