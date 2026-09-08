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

## From a bootable USB (NixOS install or reinstall)

**Bootstrap does not partition or format by default.** From the live ISO, unlock
any Linux LUKS container, activate LVM if used, and mount the intended Linux root
at `/mnt` and its EFI partition at `/mnt/boot`. Inspect `lsblk -f` first and use the
devices declared by the host's filesystem configuration. Do not run `mkfs` when
reinstalling onto existing filesystems.

From a writable checkout of this flake, with new configuration files staged:

```sh
nix run .#bootstrap -- plex-server
# Or, once its hardware configuration has been generated:
nix run .#bootstrap -- desktop
```

Without a checkout, the wrapper clones the repository and forwards the arguments:

```sh
curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/<branch>/bootstrap.sh | sh -s -- <flake-hostname>
```

Env overrides: `DOTFILES_REPO` (clone URL), `DOTFILES_DIR` (checkout path, default
`/tmp/dotfiles`). The ISO's embedded `/etc/dotfiles` is read-only; copy or clone it
to a writable directory before generating hardware configuration.

Bootstrap validates the NixOS configuration and checks that mounted root/EFI UUIDs
match it and neither mount is a subdirectory bind mount. It works without disko. Existing Secure Boot keys
and login passwords are retained; keys are created only for fresh Secure Boot
installs, and incomplete or missing reinstall keys require restoration. This still
writes a NixOS generation and bootloader: back up first. Keep existing SSH host keys
and sops keys, especially on `plex-server`, whose secrets use its SSH host key.

### Destructive installation (explicit opt-in)

```sh
nix run .#bootstrap -- antoine-dell --destructive
# The download wrapper also accepts: <flake-hostname> --destructive
```

**This erases every disk declared by the host's disko configuration**, after
configuration validation and disko's confirmation prompt. It uses the flake's
pinned disko module. Hosts without disko (`plex-server` and `desktop`) cannot use
this mode. Never use Dell's layout on a disk containing Windows.

### First installation of `desktop` alongside Windows

- Back up Windows and save its BitLocker/device-encryption recovery key off-device.
  Suspend BitLocker protection before firmware changes, disable Windows Fast Startup,
  and shrink the Windows volume in Windows Disk Management.
- Boot the ISO in UEFI mode. Temporarily disable Secure Boot if needed to boot the
  unsigned installer; do not clear the TPM.
- Inspect `lsblk -o NAME,PATH,SIZE,FSTYPE,PARTTYPE,MOUNTPOINTS` and `sudo parted -l`.
  Create/format **only new Linux partitions in unallocated space**. Dell's Linux
  layout is LUKS2 containing LVM ext4 root and encrypted swap (at least RAM-sized
  if hibernation is wanted). Desktop's disk layout is deliberately not predefined.
- Never format Windows' existing EFI or recovery partitions. Allow 2 GiB for a new
  FAT32 Linux EFI partition mounted at `/mnt/boot`; use the firmware boot menu for
  Windows with separate EFI partitions. A sufficiently large shared EFI partition
  can instead be reused without formatting, allowing automatic Windows detection.

After mounting the final Linux root and EFI filesystems (and activating any swap),
run from the writable checkout:

```sh
sudo nixos-generate-config --root /mnt --show-hardware-config > hosts/desktop/hardware-configuration.nix
# Review the generated devices and mounts before continuing.
git add hosts/desktop/hardware-configuration.nix
nix run .#bootstrap -- desktop
```

Keep the generated filesystem/swap declarations: desktop has no disko module.
For TPM unlocking, add `crypttabExtraOpts = [ "tpm2-device=auto" ];` to the generated
`boot.initrd.luks.devices.<name>` entry. For hibernation, set `boot.resumeDevice`
to the encrypted swap LV's persistent path. GPU driver settings may also be needed;
the generator does not select proprietary NVIDIA drivers.

After reboot, keep the checkout including the hardware file at `~/dotfiles`.
For a new Secure Boot installation, follow `apps/x86_64-linux/secure-boot` to enroll
keys with Microsoft trust retained, enable Secure Boot, then enroll the TPM2 slot.
Keep the LUKS passphrase and Windows recovery key. Resume BitLocker protection only
once both systems boot with the final Secure Boot settings. A reinstall with the
same enrolled keys does not require replacing the firmware keys.
