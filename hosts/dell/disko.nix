# Single NVMe: ESP + one LUKS2 container holding an LVM VG (swap + root).
# Swap lives in the container as an LV, not as a file on root: hibernate then
# resumes from /dev/vg/swap and needs no resume_offset, which a swapfile inside
# LUKS would invalidate on every reflow.
{
  disko.devices = {
    disk.main = {
      device = "/dev/nvme0n1";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
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
            size = "100%";
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
          size = "20G";
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
