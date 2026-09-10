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

| Host           | System           | Role                                    |
| -------------- | ---------------- | --------------------------------------- |
| `macbook`      | `aarch64-darwin` | work MacBook                            |
| `antoine-dell` | `x86_64-linux`   | Dell XPS 15 laptop (LUKS + secure boot) |
| `desktop`      | `x86_64-linux`   | Windows dual boot (LUKS + secure boot)  |
| `plex-server`  | `x86_64-linux`   | home media server                       |
| `vm`           | `x86_64-linux`   | standalone Home Manager VM (`VM_USER`)     |

## Layout

- `flake.nix` — inputs, hosts, packages, apps; `globals.nix` — name/email/SSH keys.
- `hosts/<name>/` — per-machine system + home config, on top of `hosts/base*.nix`.
- `modules/common/` — shared system wiring; `modules/nixos/` — NixOS modules; `modules/home/` — Home Manager modules, including `applications/<app>/` and `shell/`.
- `pkgs/` — custom derivations exported from `flake.packages`; `update-utils.nu` supplies `root_dir`, `github_headers`, and `to_sri` to package `update.nu` scripts.
- `apps/<system>/` — imperative scripts exposed as `nix run .#<name>`; `mkApp` pins Bash. `apps/aarch64-darwin/update` links to `../x86_64-linux/update`, so the invoked path selects its platform.

## Commands

| Command                                    | Effect                                                                           |
| ------------------------------------------ | -------------------------------------------------------------------------------- |
| `nix run .#apply`                          | `darwin-rebuild`/`nixos-rebuild switch` for the current host                     |
| `nix run .#update`                         | `nix flake update` + run every package's `update.nu`                             |
| `nix run .#clean`                          | GC all but the 2 latest generations                                              |
| `nix build .#checks.<system>.<host>`       | dry build a host (CI builds all)                                                 |
| `nix run ./dev`                            | treefmt (alejandra, deadnix, statix, oxfmt, Renovate validator)                  |
| `nix run .#apply-remote -- ${VM_USER}@<vm-host>` | deploy GitHub `main` to the standalone VM without a checkout (not local changes) |

`apply-remote` targets the standalone Home Manager `vm`, not the nix-darwin Linux-builder VM.

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

### Partitioning a new disk (`antoine-dell`, `desktop`)

Bootstrap never partitions or formats. Both hosts declare the same layout in their
`hardware-configuration.nix`, addressed by GPT partition label rather than UUID so a
fresh disk needs no config change: ESP labelled `disk-main-ESP`, and a LUKS2
partition labelled `disk-main-luks` holding LVM volume group `vg` with LVs `swap`
(>= RAM, for hibernate) and `root` (ext4). From the ISO, on an empty disk:

```sh
disk=/dev/nvme0n1
sudo sgdisk --zap-all "$disk"
sudo sgdisk -n 1:0:+1G -t 1:EF00 -c 1:disk-main-ESP "$disk"
sudo sgdisk -n 2:0:0 -t 2:8309 -c 2:disk-main-luks "$disk"
sudo cryptsetup luksFormat /dev/disk/by-partlabel/disk-main-luks
sudo cryptsetup open /dev/disk/by-partlabel/disk-main-luks cryptroot
sudo vgcreate vg /dev/mapper/cryptroot
sudo lvcreate -L 20G -n swap vg   # 32G on desktop
sudo lvcreate -l 100%FREE -n root vg
sudo mkfs.vfat -F 32 /dev/disk/by-partlabel/disk-main-ESP
sudo mkswap /dev/vg/swap
sudo mkfs.ext4 /dev/vg/root
sudo mount /dev/vg/root /mnt
sudo mount --mkdir -o fmask=0077,dmask=0077 /dev/disk/by-partlabel/disk-main-ESP /mnt/boot
```

On a reinstall, skip `sgdisk`/`luksFormat`/`vgcreate`/`lvcreate`/`mkfs`: `cryptsetup open`,
`sudo vgchange -ay`, mount, then run bootstrap.

#### `desktop` alongside Windows

- Back up Windows and save its BitLocker/device-encryption recovery key off-device.
  Suspend BitLocker protection before firmware changes, disable Windows Fast Startup,
  and shrink the Windows volume in Windows Disk Management.
- Boot the ISO in UEFI mode. Temporarily disable Secure Boot if needed to boot the
  unsigned installer; do not clear the TPM.
- Inspect `lsblk -o NAME,PATH,SIZE,FSTYPE,PARTTYPE,MOUNTPOINTS` and
  `sudo sgdisk -p <device>`. Do **not** `--zap-all`; create the two partitions above in
  the freed space with numbers above every Windows partition (e.g. `-n 5:0:+2G` and
  `-n 6:0:+93G`), with explicit sizes because Windows recovery usually ends the disk.
  Windows' own EFI partition stays separate, so pick Windows from the firmware boot menu.

From the writable checkout:

```sh
sudo nixos-generate-config --show-hardware-config --no-filesystems
# merge the module lists into hosts/desktop/hardware-configuration.nix, keep its filesystem block
git add hosts/desktop/hardware-configuration.nix
nix run .#bootstrap -- desktop
```

GPU driver settings may also be needed; the generator does not select proprietary
NVIDIA drivers.

After reboot, keep the checkout including the hardware file at `~/dotfiles`.
For a new Secure Boot installation, follow `apps/x86_64-linux/secure-boot` to enroll
keys with Microsoft trust retained, enable Secure Boot, then enroll the TPM2 slot.
Keep the LUKS passphrase and Windows recovery key. Resume BitLocker protection only
once both systems boot with the final Secure Boot settings. A reinstall with the
same enrolled keys does not require replacing the firmware keys.
