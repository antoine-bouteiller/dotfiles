<div align="center">

<img src="https://raw.githubusercontent.com/NixOS/nixos-artwork/master/logo/nix-snowflake-colours.svg" width="140" alt="NixOS logo" />

# dotfiles

<p align="center">
  <a href="https://github.com/antoine-bouteiller/dotfiles/actions/workflows/build.yml"><img src="https://img.shields.io/github/actions/workflow/status/antoine-bouteiller/dotfiles/build.yml?branch=main&style=for-the-badge&logo=github&label=build" alt="Build" /></a>
  <a href="https://github.com/antoine-bouteiller/dotfiles/actions/workflows/flake-update.yml"><img src="https://img.shields.io/github/actions/workflow/status/antoine-bouteiller/dotfiles/flake-update.yml?branch=main&style=for-the-badge&logo=github&label=flake%20update" alt="Flake update" /></a>
  <a href="https://github.com/antoine-bouteiller/dotfiles/commits/main"><img src="https://img.shields.io/github/last-commit/antoine-bouteiller/dotfiles?style=for-the-badge&logo=git&logoColor=white" alt="Last commit" /></a>
  <a href="flake.nix"><img src="https://img.shields.io/badge/dynamic/json?style=for-the-badge&logo=nixos&logoColor=white&label=nixpkgs&color=5277C3&url=https%3A%2F%2Fraw.githubusercontent.com%2Fantoine-bouteiller%2Fdotfiles%2Fmain%2Fflake.lock&query=%24.nodes.nixpkgs.original.ref" alt="nixpkgs channel" /></a>
</p>

</div>

Nix flake configuring every machine I use, declaratively: system config via
[nix-darwin](https://github.com/LnL7/nix-darwin) (macOS) and NixOS (Linux), user config via
[home-manager](https://github.com/nix-community/home-manager), secrets via
[sops-nix](https://github.com/Mic92/sops-nix).

Hosts:

| Host           | System           | Role                                     |
| -------------- | ---------------- | ---------------------------------------- |
| `work`       | `aarch64-darwin` | work MacBook                             |
| `antoine-dell` | `x86_64-linux`   | Dell XPS 15 laptop (disko + secure boot) |
| `plex-server`  | `x86_64-linux`   | home media server                        |

## Layout

- `flake.nix` — inputs, hosts, packages, apps; `globals.nix` — name/email/SSH keys.
- `hosts/<name>/` — per-machine system + home config, on top of `hosts/base*.nix`.
- `home-manager/` — per-application user config (`applications/`) and shell setup (`shell/`).
- `modules/` — reusable NixOS/darwin modules (auto-upgrade, secure boot, gaming, …).
- `pkgs/` — custom derivations exported from `flake.packages`, each self-updating via `update.nu`.
- `apps/<system>/` — imperative scripts exposed as `nix run .#<name>`.

## Commands

| Command                              | Effect                                                       |
| ------------------------------------ | ------------------------------------------------------------ |
| `nix run .#apply`                    | `darwin-rebuild`/`nixos-rebuild switch` for the current host |
| `nix run .#update`                   | `nix flake update` + run every package's `update.nu`         |
| `nix run .#clean`                    | GC all but the 2 latest generations                          |
| `nix build .#checks.<system>.<host>` | dry build a host (CI builds all)                             |
| `nix fmt`                            | treefmt (alejandra, deadnix, statix, oxfmt)                  |

Flakes ignore untracked files: `git add` new `.nix` files before applying.

# Install

## macOS (fresh machine)

Install Nix (flakes enabled), then let `nix-darwin` take over the machine — the first activation
is the only one that needs the full flake reference, afterwards `nix run .#apply` is enough:

```sh
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
git clone git@github.com:antoine-bouteiller/dotfiles.git ~/.dotfiles && cd ~/.dotfiles
nix run nix-darwin -- switch --flake .#<flake-hostname>
```

## From a bootable USB (fresh NixOS install)

From the NixOS installer ISO, clone this flake and install a declared host:

```
curl -sL https://raw.githubusercontent.com/<owner>/<repo>/<branch>/bootstrap.sh | sh -s -- <flake-hostname>
```

Env overrides: `DOTFILES_REPO` (clone URL), `DOTFILES_DIR` (checkout path, default `/tmp/dotfiles`).
This erases every disk declared by the host's `disko.nix`; post-install steps are in `apps/x86_64-linux/bootstrap`.
