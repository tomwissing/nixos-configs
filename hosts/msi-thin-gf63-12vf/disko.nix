# Disk layout for /dev/sda (INTENSO SSD, GPT, UEFI)
#   p1  16M      MSR            (existing, untouched)
#   p2  804.5G   BitLocker data (existing, untouched - no content = never formatted)
#   p3  1G       ESP  -> /boot  (relocated into the former free-space hole)
#   p4  148.4G   LUKS2 -> btrfs (subvols @ @home @nix @snapshots, 8G swapfile,
#             single shared space pool - no more LVM boundary exhaustion)
# destroy = false guarantees disko never wipefs's this disk (protects p2).
# alignment = 1 keeps sgdisk --align-end from moving the exact existing boundaries.
{
  disko.devices = {
    disk.sda = {
      type = "disk";
      device = "/dev/sda";
      destroy = false;
      content = {
        type = "gpt";
        partitions = {
          msr = {
            priority = 10;
            start = "34";
            end = "32767";
            type = "0C01";
            alignment = 1;
            label = "Microsoft reserved partition";
            uuid = "0C756A44-78E0-444A-A66F-1F01A5414579";
          };
          data = {
            priority = 20;
            start = "32768";
            end = "1687096463";
            type = "0700";
            alignment = 1;
            label = "Basic data partition";
            uuid = "C0B5362E-99F7-4B16-A61E-B3E9FBB925DD";
          };
          esp = {
            priority = 30;
            start = "1687097344";
            end = "1689194495";
            type = "EF00";
            alignment = 1;
            uuid = "24c25ce6-d35f-42d6-8247-de216bb5e288";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          luks = {
            priority = 40;
            start = "1689194496";
            end = "2000409230";
            type = "8300";
            alignment = 1;
            uuid = "d92ffb28-a4d2-48d4-99ce-6d0becdaaea9";
            content = {
              type = "luks";
              name = "crypt";
              settings = {
                allowDiscards = true;
              };
              extraFormatArgs = [
                "--pbkdf argon2id"
                "--key-size 512"
              ];
              content = {
                type = "btrfs";
                extraArgs = [ "-f" "-L" "nixos" ];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress-force=zstd:3" "noatime" "ssd" "space_cache=v2" ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress-force=zstd:3" "noatime" "ssd" "space_cache=v2" ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress-force=zstd:3" "noatime" "ssd" "space_cache=v2" ];
                  };
                  "@snapshots" = {
                    mountpoint = "/.snapshots";
                    mountOptions = [ "noatime" "ssd" "space_cache=v2" ];
                  };
                  "@swap" = {
                    mountpoint = "/swap";
                    swap.swapfile.size = "8G";
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
