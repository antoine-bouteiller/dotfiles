# Never run `bootstrap -- plex-server --destructive`: it would erase the media and
# backup disks. Use `--format`, which runs disko-format-mount: existing
# filesystems are kept and only mounted. enableConfig = false keeps the live
# host mounting by uuid; on reinstall, set it to true and drop the fileSystems
# entries from hardware-configuration.nix.
{
  disko.enableConfig = false;
  disko.devices.disk = let
    # One ext4 partition filling a GPT disk. _index pins the existing partition
    # number so disko adopts it instead of creating a second one.
    dataDisk = device: mountpoint: {
      inherit device;
      type = "disk";
      content = {
        type = "gpt";
        partitions.data = {
          _index = 1;
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            inherit mountpoint;
          };
        };
      };
    };
  in {
    main = {
      device = "/dev/sda";
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
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
    media = dataDisk "/dev/sdb" "/mnt/media";
    backup = dataDisk "/dev/sdc" "/mnt/backup";
  };
}
