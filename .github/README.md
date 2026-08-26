# Install

```
git clone git@github.com:antoine-bouteiller/dotfiles.git ~/.dotfiles
```

## From a bootable USB (fresh NixOS install)

From the NixOS installer ISO, clone this flake and install a declared host:

```
curl -sL https://raw.githubusercontent.com/<owner>/<repo>/<branch>/bootstrap.sh | sh -s -- <flake-hostname>
```

Env overrides: `DOTFILES_REPO` (clone URL), `DOTFILES_DIR` (checkout path, default `/tmp/dotfiles`).
This erases every disk declared by the host's `disko.nix`; post-install steps are in `apps/x86_64-linux/bootstrap`.
