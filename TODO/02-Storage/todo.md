# TODO — 02 Storage (ZFS + disko)

**Status:** ~ reformat pending (early v1 milestone) · **Owner:** zfs-disko skill · **File refs:** `hosts/homelab/disko.nix`, `hardware-configuration.nix`, `modules/system/zfs.nix`, `modules/system/storage-layout.nix`

## Installed (Dell test box) — current
- [x] disko GPT: 1G ESP `/boot` + ZFS `rpool`
- [x] Datasets: `rpool/nix` (/nix), `rpool/root` (/), `rpool/fast` → `/fast`, `rpool/slow` → `/slow`
- [x] `networking.hostId` set (keep forever)
- [x] `boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages`
- [x] ARC cap via `zfs.zfs_arc_max=1073741824` kernel param (Dell 6GB)
- [x] Declarative directory layout (`storage-layout.nix`, tmpfiles, `root:media 2775`) — deployed + verified

## 🔴 NEXT MILESTONE — Dell reformat to mirror prod (2026-08-08 ruling)
**Goal:** the Dell's layout LOOKS like prod's `/fast` + `/slow` (separate datasets, distinct recordsize/compression) so the prod switch is drop-in.
- [ ] Re-architect `disko.nix` for the Dell: `/fast` + `/slow` as separate ZFS datasets mirroring prod pool semantics (SSD vs HDD tuning where the single disk allows)
- [ ] Confirm backup of current state before reformat (restic or snapshot)
- [ ] Reformat, reinstall (nixos-anywhere), re-verify all §13 checks
- [ ] After reformat: prod switch contract holds — only `disko.nix` + `hardware-configuration.nix` + `zfsArcMax` change at prod time

## Directory layout (OpenCode.md §5) — declarative via storage-layout.nix
- [x] `/fast/user/hey/{work/{audio,video,images,literature,documents}/{apple,windows,linux},academic,downloads}`
- [x] `/fast/immich` — Immich-managed black box (service creates)
- [x] `/fast/mail` — Maildir (SNM creates)
- [x] `/fast/backups/postgres` — nightly dumps + restic source
- [x] `/fast/containers` — Docker arr/request container config dirs (2026-08-08)
- [x] `/slow/shared-media/video/{shows,movies}`
- [x] `/slow/shared-media/audio/{music,audiobooks}` (podcasts dir dropped — out of scope)
- [x] `/slow/shared-media/literature/{books}`
- [x] `/slow/downloads/{qbittorrent,sabnzbd,slskd}` — *arr hardlink source
- [x] `media` group + `SupplementaryGroups=media` on immich + nextcloud php (+ media services as built)

## Prod migration (future hardware) — contract
- [ ] New `hardware-configuration.nix` (12th-gen i5)
- [ ] New `disko.nix`: pools `fast` (2×4TB SSD RAID1) + `slow` (2×8TB HDD RAID1), same mountpoints
- [ ] Bump `zfsArcMax` (64GB RAM)
- [ ] **Migration contract:** ONLY these 3 files change — disko.nix, hardware-configuration.nix, zfsArcMax in settings.nix. Nothing else.

## Verification
- [ ] `zpool status` healthy
- [ ] ARC within cap (`arcstat`/`zfs-stats`)
- [ ] `/fast` + `/slow` mounted at expected paths
- [ ] After reformat: full §13 suite green again
