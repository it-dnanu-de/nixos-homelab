# hosts/homelab/disko.nix
# OpenCode.md §5 — single-disk ZFS, Dell test box (223.6G Intenso SSD).
# Device is by-id so the Ventoy USB at /dev/sdb can never match, even if
# letters re-enumerate. Prod: replace this file (two pools, same mountpoints)
# per the §2 migration contract.
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/disk/by-id/ata-Intenso_SSD_SATA_III_AA000000000000001803";
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
              mountOptions = [ "umask=0077" ];
            };
          };
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
        };
      };
    };

    zpool.rpool = {
      type = "zpool";
      rootFsOptions = {
        canmount = "off";
        mountpoint = "none";
        compression = "zstd";
        atime = "off";
        "com.sun:auto-snapshot" = "false";
      };
      datasets = {
        root = { type = "zfs_fs"; mountpoint = "/"; };
        nix  = { type = "zfs_fs"; mountpoint = "/nix"; };
        work = { type = "zfs_fs"; mountpoint = "/work"; };
        fast = { type = "zfs_fs"; mountpoint = "/fast"; };
        slow = { type = "zfs_fs"; mountpoint = "/slow"; };
      };
    };
  };
}
