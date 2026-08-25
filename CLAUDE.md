# dotfiles — repo conventions

Nix flakes + home-manager, multi-host, cross-platform (nix-darwin on macOS and NixOS on Linux).
Secrets via sops-nix. Entry point: `flake.nix`.

## Critical

- **`git add` before applying.** Flakes ignore untracked files — a new `.nix` file is invisible to
  the build until staged. Stage first, then apply.
- **Format with `nix fmt`.** The flake formatter is treefmt (alejandra, deadnix, statix,
  oxfmt, renovate-validator); config in `treefmt.nix`.
- **The pre-commit hook is `.githooks/pre-commit`,** a tracked bash script running gitleaks +
  treefmt. Enable it once per clone with `git config core.hooksPath .githooks`; it resolves its
  tools through `nix` at run time, so garbage collection never breaks it. It needs `flake.nix` to
  parse — while the flake is mid-edit and broken, commit with `--no-verify`. It also refuses
  partially staged files, since formatting them would commit their unstaged hunks.

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
- `hosts/<name>/{default,home}.nix` + `hosts/base*.nix` — per-machine config. Darwin host: `pelico`.
- `home-manager/applications/<app>/` — user program config; `home-manager/shell/` — zsh, git, ssh.
- `pkgs/<name>/` — custom derivations, exported in `flake.packages`. Each bumps itself via a
  `passthru.updateScript` → `update.nu` (nushell), driven by `nix run .#update`.
- `modules/` — NixOS/darwin system modules; `dev/` — dev-shell flake (treefmt + git hooks).

## Patterns

- Feature toggles use the `local.home-manager.<name>.enable` option pattern — follow it for new opt-in modules.
- Prefer nixpkgs packages over Homebrew casks when both exist.
- Renovate owns GitHub Actions + pinned Docker digests; the weekly `flake-update.yml` workflow owns Nix inputs.
