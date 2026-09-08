# Dual boot: Windows owns partitions 1-4 (EFI, MSR, C:, recovery); only the Linux
# partitions below are declared. Apply with `bootstrap -- desktop --format`, which
# runs disko-format-mount: it never clears the table and skips anything that already
# has a filesystem, so undeclared partitions are untouched. Fill in the three
# CHECK values from `lsblk -o NAME,PATH,SIZE` and `sudo sgdisk -p <device>` on the
# ISO before the first run.
{
  disko.devices = {
    disk.main = {
      device = "/dev/nvme0n1"; # Windows: p1 MSR 128M, p2 EFI 100M, p3 C: 834.5G, p4 recovery 815M
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          # _index must be above every Windows partition number: disko falls back to
          # rewriting the type/name of an existing partition with the same number.
          # start defaults to the largest free block, so both land in the freed space.
          # Sizes are explicit (not 100%) because Windows recovery usually sits at the
          # end of the disk and "-0" would overlap it.
          ESP = {
            _index = 5;
            size = "2G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "fmask=0077"
                "dmask=0077"
              ];
            };
          };
          luks = {
            _index = 6;
            size = "93G"; # ~96G freed minus the 2G ESP and lsblk rounding
            content = {
              type = "luks";
              name = "cryptroot";
              # Passphrase slot is enrolled by the installer prompt; the TPM2
              # slot is added post-install with systemd-cryptenroll and the
              # passphrase stays as the recovery path.
              settings = {
                crypttabExtraOpts = ["tpm2-device=auto"];
                allowDiscards = true; # NVMe TRIM through the LUKS mapping
              };
              content = {
                type = "lvm_pv";
                vg = "vg";
              };
            };
          };
        };
      };
    };

    lvm_vg.vg = {
      type = "lvm_vg";
      lvs = {
        # >= RAM, else hibernate fails to write its image.
        swap = {
          size = "32G";
          content = {
            type = "swap";
            resumeDevice = true;
          };
        };
        root = {
          size = "100%FREE";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
