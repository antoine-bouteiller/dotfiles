# dotfiles — repo conventions

Nix flakes + home-manager, multi-host, cross-platform (nix-darwin on macOS and NixOS on Linux).
Secrets via sops-nix. Entry point: `flake.nix`.

## Critical

- **`git add` before applying.** Flakes ignore untracked files — a new `.nix` file is invisible to
  the build until staged. Stage first, then apply.
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
- `hosts/<name>/{default,home}.nix` + `hosts/base*.nix` — per-machine config. Integrated hosts: `dell`, `desktop`, `plex-server`, `macbook`; `vm` is standalone Home Manager for `VM_USER`; `iso` has neither common modules nor Home Manager.
- `modules/common/` — shared system wiring; `modules/nixos/` — NixOS modules; `modules/home/` — Home Manager modules (`applications/<app>/`, `shell/`).
- `pkgs/<name>/` — custom derivations with `passthru.updateScript` → `update.nu`; `pkgs/update-utils.nu` exports `root_dir`, `github_headers`, and `to_sri` for updater scripts.
- `apps/<system>/` — app scripts. `flake.nix` `mkApp` pins Bash; `apps/aarch64-darwin/update` is a symlink to `../x86_64-linux/update`, selecting its platform from the invoked path.
- `dev/` — dev-shell flake (treefmt + git hooks).

## Ownership

- Integrated Home Manager imports `hosts/<name>/home.nix` for `host.user`, shares `modules/home`, disables the release check, and forwards special args; `hosts/base-nixos.nix` owns the normal Linux user, while standalone `vm` imports its home directly with explicit identity.
- `local.home-manager.sourcePath` is the runtime path for agent files, Pi secrets, Zed files, and zsh; integrated homes default to `flakePath`, while `vm` uses `${inputs.self}` for checkout-free remote deployment.
- `local.nixos.workstation` selects desktop, the Home Manager workstation profile, and shared `dell`/`desktop` packages; `local.nixos.desktop` owns resolved, PipeWire, Bluetooth, and xwayland-satellite; Darwin selects the Home Manager profile directly.
- `local.home-manager.desktop` owns Niri and terminal selection; use `desktop.extraNiriConfig` for host outputs and keep Steam scaling plus `eDP-1` in host files.
- Set MCP servers with `programs.mcp.servers`; agents enable `programs.mcp` when servers exist.
- Shared Servarr integration is `hosts/plex-server/media/arr/shared.nix`; upstream Immich owns database extensions/setup; the download bundle owns Podman.
- `nix run .#apply-remote -- ${VM_USER}@<vm-host>` deploys GitHub `main` to standalone `vm`, not local changes or the nix-darwin Linux-builder VM.

## Patterns

- Feature toggles use the `local.home-manager.<name>.enable` option pattern. Write them with
  `lib/module.nix`, passed to every system and home-manager module as the `mkModule` special arg:
  `{mkModule, ...} @ args: mkModule args "local.home-manager.foo" {description = "…"; config = {cfg}: {…};}`.
  It declares the `enable` toggle, binds `cfg`, and wraps the body in `mkIf cfg.enable`; extra options
  go under `options`, module imports under `imports`.
- Prefer nixpkgs packages over Homebrew casks when both exist.
- Renovate owns GitHub Actions + pinned Docker digests; the weekly `flake-update.yml` workflow owns Nix inputs.
