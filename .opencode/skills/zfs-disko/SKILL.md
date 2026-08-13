---
name: zfs-disko
description: Use when dealing with storage — disko partitioning, ZFS pools/datasets, ARC tuning, backup sources, or the /work /fast /slow layout. Enforces the migration contract.
---

# ZFS + Disko Storage

## Layout (OpenCode.md §5, 3 pools — 2026-08-12)
- Test box: single 250GB SSD, GPT: 1G ESP `/boot` + rest ZFS `rpool`, datasets mirroring the 3 prod pools.
- Prod: `work` pool (2x1TB NVMe RAID1) + `fast` pool (2x2TB SSD RAID1) + `slow` pool (2x4TB HDD RAID1), same mountpoints.
- Datasets: `rpool/{root,nix,work,fast,slow}` — root `/`, nix `/nix`, work `/work`, fast `/fast`, slow `/slow`. Different recordsize per pool (work/fast 128K, slow 1M).

## Directory tree (v2)
```
/work/shared/
├── library/{video,music,sfx}                  # reusable assets
├── templates/                                 # project skeletons
└── projects/<ProjectName>/
    ├── 00_admin/ 01_docs/ 02_assets/
    ├── 03_media/{raw,processed}               # raw = read-only source of truth
    ├── 04_project-files/{resolve,premiere,...}  # per-app session files
    └── 05_exports/{preview,interchange,final}

/fast/users/<user>/{notes,photos,documents,paperless}   # filesystem = user files; Nextcloud data + Memories index here
/fast/{mail,backups/postgres}                   # Maildir, nightly dumps

/slow/shared-media/video/{shows,movies}
/slow/shared-media/audio/{music,audiobooks}
/slow/shared-media/literature/{books}
/slow/downloads/{qbittorrent,sabnzbd,slskd}     # *arr hardlink source
```
- Media services + nextcloud get supplementary group `media`; dirs `root:media 2775` (setgid).
- lowercase-kebab-case, multi-OS safe. No archive tier (Restic = version history).
- **Storage policy:** finished project → delete `03_media/processed/` (regenerable), move `03_media/raw/` to cold storage, keep the rest (tiny).

## Mandatory settings
- `networking.hostId = "<8 hex>";` — generate once, keep forever.
- `boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;`
- ARC cap is a `settings.nix` parameter; Dell default `zfs.zfs_arc_max=1073741824`.

## Migration contract (the point of all this)
Config references abstract paths `/work`, `/fast`, `/slow` via `settings.nix` only.
Moving to prod = new `hardware-configuration.nix` + new `disko.nix` (three pools, same mountpoints) + bump `zfsArcMax`. Nothing else changes.

## Backups coupling
- `/fast/backups/postgres` = nightly `services.postgresqlBackup` (host app DBs; Nextcloud's DB lives in the podman AIO container, not here).
- Restic includes `/fast`, `/var/lib` service state, `/etc/nixos`. Excludes `/slow/shared-media`, `/slow/downloads`, `/work` (active), caches. Prune 7d/4w/12m to B2.
