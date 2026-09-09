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
| `nix run .#update-claude`            | bump only claude-code to latest release, then `apply`        |
| `nix run .#clean`                    | GC all but the 2 latest generations                          |
| `nix build .#checks.<system>.<host>` | dry build a host (CI builds all)                             |

## Layout

- `flake.nix` — hosts wired via `mkDarwinHost`/`mkNixosHost` (`lib/default.nix`); `globals.nix` = name/email/keys.
- `hosts/<name>/{default,home}.nix` + `hosts/base*.nix` — per-machine config. Darwin host: `work`.
- `home-manager/applications/<app>/` — user program config; `home-manager/shell/` — zsh, git, ssh.
- `pkgs/<name>/` — custom derivations, exported in `flake.packages`. Each bumps itself via a
  `passthru.updateScript` → `update.nu` (nushell), driven by `nix run .#update`.
- `modules/` — NixOS/darwin system modules; `dev/` — dev-shell flake (treefmt + git hooks).

## Patterns

- Feature toggles use the `local.home-manager.<name>.enable` option pattern. Write them with
  `lib/module.nix`, passed to every system and home-manager module as the `mkModule` special arg:
  `{mkModule, ...} @ args: mkModule args "local.home-manager.foo" {description = "…"; config = {cfg}: {…};}`.
  It declares the `enable` toggle, binds `cfg`, and wraps the body in `mkIf cfg.enable`; extra options
  go under `options`, module imports under `imports`.
- Prefer nixpkgs packages over Homebrew casks when both exist.
- Renovate owns GitHub Actions + pinned Docker digests; the weekly `flake-update.yml` workflow owns Nix inputs.
