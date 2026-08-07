# TODO — 09 Media Player (Jellyfin)

**Status:** ⬜ not started · **Owner:** nixos-builder · **Module:** `modules/services/jellyfin.nix`

> **Jellyfin is the ONLY player** (LOCKED 2026-08-08). Client = LiquidFin (Apple, personal v1 choice; v2 server is client-agnostic). Navidrome/Audiobookshelf/Booklore all dropped.

## Jellyfin (`services.jellyfin`) — `watch.nanulab.de`
- [ ] Libraries (all point into `/slow/shared-media`):
  - [ ] Movies: `/slow/shared-media/video/movies`
  - [ ] TV Shows: `/slow/shared-media/video/shows`
  - [ ] Music: `/slow/shared-media/audio/music`
  - [ ] Audiobooks: `/slow/shared-media/audio/audiobooks`
  - [ ] Books (e-books only — EPUB/PDF): `/slow/shared-media/literature/books`
- [ ] Reads *arr NFO/poster files natively
- [ ] GPU: SNB iGPU → `intel-vaapi-driver`; prod → `intel-media-driver`
- [ ] nginx user-tier vhost + ACL
- [ ] Admin account + library setup (1% manual)
- [ ] `media` group (already defined; Jellyfin joins it)

## Client
- [ ] **LiquidFin** (App Store, free tier) — the Apple client. Document connection in README / profile page. (v1 personal choice; v2 documents alternatives: Swiftfin, Infuse, web.)

## Dropped (2026-08-08)
- 🗑 Navidrome — Jellyfin does music
- 🗑 Audiobookshelf — podcasts dropped; audiobooks manual → Jellyfin library
- 🗑 Booklore + MariaDB — e-books served by Jellyfin book library (iPad/iPhone/Mac read them; Apple TV excludes e-books)

## Audiobooks (manual path)
- [ ] Document the manual flow: drop audiobook folders into `/slow/shared-media/audio/audiobooks` → Jellyfin scan → LiquidFin plays
- [ ] Optional: an audiobook renamer/organizer later if it matters (Shelfarr watch — not packaged)

## Shared
- [ ] nginx user-tier vhost
- [ ] Restic include state
