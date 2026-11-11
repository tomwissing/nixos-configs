# Disk layout for the Acer Aspire Switch 10 E (SW3-013) 32 GB Hynix eMMC.
#
#   p1  512M   ESP  -> /boot   (vfat)
#   p2  ~31G   btrfs subvols   @  @home  @nix  @snapshots
#
# Deliberately no swap partition: swap on eMMC is pure wear, and zramSwap
# in switch10e.nix covers the 2 GB of RAM instead.
#
# The eMMC has appeared as both /dev/mmcblk0 and /dev/mmcblk1 across boots.
# Use its stable hardware ID so changing device numbering cannot select
# the wrong disk: mmc-HBG4e__0x6ffb64d0.
{
  disko.devices = {
    disk.emmc = {
      type = "disk";
      device = "/dev/disk/by-id/mmc-HBG4e__0x6ffb64d0";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            priority = 10;
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            priority = 20;
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [
                "-f"
                "-L"
                "nixos"
              ];
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress-force=zstd:3"
                    "noatime"
                    "ssd"
                    "space_cache=v2"
                  ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "compress-force=zstd:3"
                    "noatime"
                    "ssd"
                    "space_cache=v2"
                  ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress-force=zstd:3"
                    "noatime"
                    "ssd"
                    "space_cache=v2"
                  ];
                };
                "@snapshots" = {
                  mountpoint = "/.snapshots";
                  mountOptions = [
                    "noatime"
                    "ssd"
                    "space_cache=v2"
                  ];
                };
              };
            };
          };
        };
      };
    };
  };
}
