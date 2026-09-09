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
| `desktop`      | `x86_64-linux`   | Windows dual boot (disko + secure boot)  |
| `plex-server`  | `x86_64-linux`   | home media server                        |

## Layout

- `flake.nix` — inputs, hosts, packages, apps; `globals.nix` — name/email/SSH keys.
- `hosts/<name>/` — per-machine system + home config, on top of `hosts/base*.nix`.
- `home-manager/` — per-application user config (`applications/`) and shell setup (`shell/`).
- `modules/` — reusable NixOS/darwin modules (auto-upgrade, secure boot, gaming, …).
- `pkgs/` — custom derivations exported from `flake.packages`, each self-updating via `update.nu`.
- `apps/<system>/` — imperative scripts exposed as `nix run .#<name>`.

## Commands

| Command                              | Effect                                                          |
| ------------------------------------ | --------------------------------------------------------------- |
| `nix run .#apply`                    | `darwin-rebuild`/`nixos-rebuild switch` for the current host    |
| `nix run .#update`                   | `nix flake update` + run every package's `update.nu`            |
| `nix run .#clean`                    | GC all but the 2 latest generations                             |
| `nix build .#checks.<system>.<host>` | dry build a host (CI builds all)                                |
| `nix run ./dev`                      | treefmt (alejandra, deadnix, statix, oxfmt, Renovate validator) |

Flakes ignore untracked files: `git add` new `.nix` files before applying.

## Development

Run `direnv allow` from the repository root (or `nix develop ./dev`). The independent
`dev/` flake provides treefmt and gitleaks; `git-hooks.nix` installs their pre-commit hooks.
These tools are not installed by the host configurations. Pre-commit preserves unstaged
changes; when formatting changes a file, re-stage it and retry the commit.

Use `treefmt` in the dev shell or `nix run ./dev` from the repository root.
Update the dev inputs separately with `nix flake update --flake ./dev`; CI updates both locks weekly.

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
```

Without a checkout, the wrapper clones the repository and forwards the arguments:

```sh
curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/<branch>/bootstrap.sh | sh -s -- <flake-hostname>
```

Env overrides: `DOTFILES_REPO` (clone URL), `DOTFILES_DIR` (checkout path, default
`/tmp/dotfiles`). The ISO's embedded `/etc/dotfiles` is read-only; copy or clone it
to a writable directory before generating hardware configuration.

Bootstrap validates the NixOS configuration and checks that mounted root/EFI UUIDs
match it and neither mount is a subdirectory bind mount. Existing Secure Boot keys
and login passwords are retained; keys are created only for fresh Secure Boot
installs, and incomplete or missing reinstall keys require restoration. This still
writes a NixOS generation and bootloader: back up first. Keep existing SSH host keys
and sops keys, especially on `plex-server`, whose secrets use its SSH host key.

### Partitioning with disko (explicit opt-in)

Both modes use the flake's pinned disko module and the host's `disko.nix`; hosts
without one fail before touching any disk. The download wrapper accepts the same
flags.

```sh
nix run .#bootstrap -- desktop --format
nix run .#bootstrap -- antoine-dell --destructive
```

`--format` is non-destructive: it never clears a partition table that already has
one, creates only declared partitions that do not exist yet (by number), and skips
`mkfs`/`luksFormat`/`vgcreate`/`lvcreate`/`mkswap` on anything that already holds a
signature, then mounts under `/mnt`. Undeclared partitions are never touched. It does
rewrite the label, type code and GUID of every _declared_ partition number, so a
`_index` that collides with a foreign partition corrupts its metadata: pin `_index`
above existing partitions when sharing a disk. Dry-run first with
`nix build --print-out-paths .#nixosConfigurations.<host>.config.system.build.formatMount`
and read the generated script against `sudo sgdisk -p <device>`.

`--destructive` **erases every disk declared by the host's disko configuration**
after disko's confirmation prompt. Never use it on a disk containing Windows.

#### `plex-server`

`hosts/plex-server/disko.nix` declares the system disk plus the `media` and `backup`
data disks, with `disko.enableConfig = false` so the live host keeps mounting its
filesystems from `hardware-configuration.nix`. Only `--format` is safe there: it
adopts the existing partitions and mounts them. **`--destructive` erases the media
and backup disks too.**

### First installation of `desktop` alongside Windows

- Back up Windows and save its BitLocker/device-encryption recovery key off-device.
  Suspend BitLocker protection before firmware changes, disable Windows Fast Startup,
  and shrink the Windows volume in Windows Disk Management.
- Boot the ISO in UEFI mode. Temporarily disable Secure Boot if needed to boot the
  unsigned installer; do not clear the TPM.
- Inspect `lsblk -o NAME,PATH,SIZE,FSTYPE,PARTTYPE,MOUNTPOINTS` and
  `sudo sgdisk -p <device>`, then fill in the `CHECK` values in
  `hosts/desktop/disko.nix`: the disk device, `_index` numbers above every Windows
  partition, and the LUKS size (freed space minus the 2 GiB Linux EFI partition).
  Sizes stay explicit because Windows recovery usually ends the disk. The layout
  is Dell's (LUKS2 > LVM > swap + ext4 root) placed in the freed space; Windows'
  EFI and recovery partitions are not declared and therefore never formatted. Use
  the firmware boot menu to pick Windows, since the EFI partitions are separate.

From the writable checkout:

```sh
sudo nixos-generate-config --show-hardware-config --no-filesystems > hosts/desktop/hardware-configuration.nix
git add hosts/desktop/disko.nix hosts/desktop/hardware-configuration.nix
nix run .#bootstrap -- desktop --format
```

The hardware file needs no mounts (`--no-filesystems`: disko owns `fileSystems`,
`swapDevices` and `boot.resumeDevice`). Bootstrap validates the configuration,
then disko creates and mounts the Linux partitions and the install proceeds.
`--format` is idempotent, so a reinstall reruns the same command onto the existing
filesystems.
GPU driver settings may also be needed; the generator does not select proprietary
NVIDIA drivers.

After reboot, keep the checkout including the hardware file at `~/dotfiles`.
For a new Secure Boot installation, follow `apps/x86_64-linux/secure-boot` to enroll
keys with Microsoft trust retained, enable Secure Boot, then enroll the TPM2 slot.
Keep the LUKS passphrase and Windows recovery key. Resume BitLocker protection only
once both systems boot with the final Secure Boot settings. A reinstall with the
same enrolled keys does not require replacing the firmware keys.
