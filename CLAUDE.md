# dotfiles — repo conventions

Nix flakes + home-manager, multi-host, cross-platform (nix-darwin on macOS and NixOS on Linux).
Secrets via sops-nix. Entry point: `flake.nix`.

## Critical

- **`git add` before applying.** Flakes ignore untracked files — a new `.nix` file is invisible to
  the build until staged. Stage first, then apply. This includes new `.private/default.nix` and
  `.private/home.nix` when the optional private checkout is in use.
- **Format with `nix run ./dev`** (or `treefmt` inside the dev shell); config in `dev/treefmt.nix`.
  The independent `dev/` flake keeps formatting tools out of host installations.
- **Enter the dev shell with `direnv allow` or `nix develop ./dev`.** `git-hooks.nix` installs
  pre-commit hooks (gitleaks + treefmt), configured in `dev/flake.nix`. Formatting changes must
  be re-staged before retrying the commit; pre-commit preserves unstaged changes.

## Commands

| Command                              | Effect                                                       |
| ------------------------------------ | ------------------------------------------------------------ |
| `nix run .#apply`                    | `darwin-rebuild`/`nixos-rebuild switch` for the current host |
| `nix run .#update`                   | `nix flake update` + run every package's `update.nu`         |
| `nix run .#clean`                    | GC all but the 2 latest generations                          |
| `nix build .#checks.<system>.<host>` | dry build a host (CI builds all)                             |

## Layout

- `flake.nix` — hosts wired via `mkDarwinHost`/`mkNixosHost` (`lib/default.nix`); `globals.nix` = name/email/keys.
- `hosts/<name>/{default,home}.nix` + `hosts/base*.nix` — per-machine config. Integrated hosts: `dell`, `desktop`, `plex-server`, `macbook`; `vm` is standalone Home Manager for optional private `hosts.vm.user` (public `ci-user` fixture); `iso` has neither common modules nor Home Manager.
- `modules/common/` — shared system wiring; `modules/nixos/` — NixOS modules; `modules/home/` — Home Manager modules (`applications/<app>/`, `shell/`).
- `pkgs/<name>/` — custom derivations with `passthru.updateScript` → `update.nu`; `pkgs/update-utils.nu` exports `root_dir`, `github_headers`, and `to_sri` for updater scripts.
- `apps/<system>/` — Nushell app scripts. `flake.nix` `mkApp` pins Nushell with `--no-config-file`; `apps/aarch64-darwin/update` is a symlink to `../x86_64-linux/update`, selecting its platform from the invoked path. `apps/private-config.nu` owns checkout validation and local Git snapshot references.
- `lib/nix-settings.json` owns shared Nix features, caches, and signing keys; `hosts/base.nix` imports it and `apps/config.nu` renders it for bootstrap.
- `dev/` — dev-shell flake (treefmt + git hooks).

## Ownership

- Integrated Home Manager imports `hosts/<name>/home.nix` for `host.user`, shares `modules/home`, disables the release check, and forwards special args; `hosts/base-nixos.nix` owns the normal Linux user, while standalone `vm` imports its home directly with explicit identity.
- Agent modules and assets live in `modules/home/applications/agents/{claude-code,pi,skills}`. Only skills use out-of-store links; agent context, settings, and hooks come from the Nix store.
- `local.home-manager.sourcePath` is the runtime path for agent skills, Pi secrets, Zed files, and zsh; integrated homes default to `flakePath`, while `vm` uses `${inputs.self}` for checkout-free remote deployment.
- `privateConfig` is an optional non-flake input. The tracked `private-config/` fixture is empty;
  `.private/` is an independent ignored Git repository selected by local apply scripts. Its
  `default.nix` may set `hosts.vm.user`; its optional `home.nix` is the single shared private
  Home Manager hook. Private modules own work identity and host-specific work shell settings.
  `.private/` must be a directory rather than a symlink. No legacy environment variables are
  required. Never copy private values into public files or output them in diagnostics.
- `local.nixos.workstation` selects desktop, the Home Manager workstation profile, and shared `dell`/`desktop` packages; `local.nixos.desktop` owns resolved, PipeWire, Bluetooth, and xwayland-satellite; Darwin selects the Home Manager profile directly.
- `local.home-manager.desktop` owns Niri and terminal selection; use `desktop.extraNiriConfig` for host outputs and keep Steam scaling plus `eDP-1` in host files.
- Set MCP servers with `programs.mcp.servers`; agents enable `programs.mcp` when servers exist.
- Shared Servarr integration is `hosts/plex-server/media/arr/shared.nix`; upstream Immich owns database extensions/setup; the download bundle owns Podman.
- `nix run .#apply-remote -- <user>@<vm-host>` deploys Git-tracked local contents of the public
  checkout and optional `.private/`, including uncommitted edits, to standalone `vm`. Stage new
  files first; no commit or push is required. It copies Nix source snapshots to the VM and
  evaluates the same snapshot's VM username before bootstrap, requiring the SSH login to match.
  Remote preparation and activation run `apps/remote.nu` using the archived nixpkgs' Nushell;
  the pre-Nix installer and SSH transport retain a minimal Bash bridge.

## Patterns

- Feature toggles use the `local.home-manager.<name>.enable` option pattern. Write them with
  `lib/module.nix`, passed to every system and home-manager module as the `mkModule` special arg:
  `{mkModule, ...} @ args: mkModule args "local.home-manager.foo" {description = "…"; config = {cfg}: {…};}`.
  It declares the `enable` toggle, binds `cfg`, and wraps the body in `mkIf cfg.enable`; extra options
  go under `options`, module imports under `imports`.
- Prefer nixpkgs packages over Homebrew casks when both exist.
- Renovate owns GitHub Actions + pinned Docker digests; the weekly `flake-update.yml` workflow owns Nix inputs.
