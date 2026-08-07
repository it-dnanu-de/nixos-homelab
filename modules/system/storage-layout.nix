# modules/system/storage-layout.nix
# OpenCode.md §5 — declarative directory layout on /fast and /slow.
# Directories: root:media 2775 (setgid) so media services sharing the group
# can write. Created by systemd-tmpfiles (persist across reboot).
{ lib, ... }:
{
  # media group: shared by all media services + nextcloud + immich (§5)
  users.groups.media = { };

  systemd.tmpfiles.rules = [
    # /fast — user hey workspace
    "d /fast/user/hey 2775 root media -"
    "d /fast/user/hey/work 2775 root media -"
    "d /fast/user/hey/work/audio 2775 root media -"
    "d /fast/user/hey/work/audio/apple 2775 root media -"
    "d /fast/user/hey/work/audio/windows 2775 root media -"
    "d /fast/user/hey/work/audio/linux 2775 root media -"
    "d /fast/user/hey/work/video 2775 root media -"
    "d /fast/user/hey/work/video/apple 2775 root media -"
    "d /fast/user/hey/work/video/windows 2775 root media -"
    "d /fast/user/hey/work/video/linux 2775 root media -"
    "d /fast/user/hey/work/images 2775 root media -"
    "d /fast/user/hey/work/images/apple 2775 root media -"
    "d /fast/user/hey/work/images/windows 2775 root media -"
    "d /fast/user/hey/work/images/linux 2775 root media -"
    "d /fast/user/hey/work/literature 2775 root media -"
    "d /fast/user/hey/work/literature/apple 2775 root media -"
    "d /fast/user/hey/work/literature/windows 2775 root media -"
    "d /fast/user/hey/work/literature/linux 2775 root media -"
    "d /fast/user/hey/work/documents 2775 root media -"
    "d /fast/user/hey/work/documents/apple 2775 root media -"
    "d /fast/user/hey/work/documents/windows 2775 root media -"
    "d /fast/user/hey/work/documents/linux 2775 root media -"
    "d /fast/user/hey/academic 2775 root media -"
    "d /fast/user/hey/downloads 2775 root media -"
    # /fast/backups
    "d /fast/backups 2775 root media -"
    "d /fast/backups/postgres 2770 root postgres -"
    # /fast/containers — bind-mounted /config dirs for the arr/request Docker containers
    "d /fast/containers 2775 root media -"
    # /fast/immich + /fast/mail are created by their services (immich module,
    # SNM). Not listed here to avoid ownership fights.

    # /slow — shared media
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
