# modules/system/storage-layout.nix
# OpenCode.md §5 — declarative directory layout v2 (2026-08-12).
# 3 pools: /work (active creative), /fast (apps+user cloud), /slow (media library).
# Directories: root:media 2775 (setgid) so media services sharing the group
# can write. Created by systemd-tmpfiles (persist across reboot).
{ lib, ... }:
{
  # media group: shared by all media services + nextcloud (§5)
  users.groups.media = { };

  systemd.tmpfiles.rules = [
    # ── /work — active creative projects (NVMe) ──
    "d /work 2775 root media -"
    "d /work/shared 2775 root media -"
    "d /work/shared/library 2775 root media -"
    "d /work/shared/library/video 2775 root media -"
    "d /work/shared/library/music 2775 root media -"
    "d /work/shared/library/sfx 2775 root media -"
    "d /work/shared/templates 2775 root media -"
    "d /work/shared/projects 2775 root media -"

    # ── /fast — user cloud + apps (SSD) ──
    "d /fast 2775 root media -"
    "d /fast/users 2775 root media -"
    "d /fast/backups 2775 root media -"
    "d /fast/backups/postgres 2770 root postgres -"
    "d /fast/containers 2775 root media -"
    # /fast/users/<user>/{notes,photos,documents,paperless} + /fast/mail are
    # created by the user-provisioning layer / SNM — not listed here to avoid
    # ownership fights. Nextcloud data dir + Memories point into /fast/users.

    # ── /slow — media library (HDD) ──
    "d /slow 2775 root media -"
    "d /slow/shared-media 2775 root media -"
    "d /slow/shared-media/video 2775 root media -"
    "d /slow/shared-media/video/shows 2775 root media -"
    "d /slow/shared-media/video/movies 2775 root media -"
    "d /slow/shared-media/audio 2775 root media -"
    "d /slow/shared-media/audio/music 2775 root media -"
    "d /slow/shared-media/audio/audiobooks 2775 root media -"
    "d /slow/shared-media/literature 2775 root media -"
    "d /slow/shared-media/literature/books 2775 root media -"

    # /slow/downloads — *arr hardlink source (same pool as shared-media)
    "d /slow/downloads 2775 root media -"
    "d /slow/downloads/qbittorrent 2775 root media -"
    "d /slow/downloads/sabnzbd 2775 root media -"
    "d /slow/downloads/slskd 2775 root media -"
  ];
}
