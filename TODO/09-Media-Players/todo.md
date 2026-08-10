# TODO — 09 Media Player (Jellyfin — frontend-media container)

**Status:** ⬜ not started · **Owner:** builder · **Module:** `modules/containers/jellyfin.nix`

> **Jellyfin is the ONLY player** (LOCKED 2026-08-08). NixOS container in frontend-media zone `.50`, macvlan, served via nginx at `media.nanulab.de`. Client = LiquidFin (user choice).

## Jellyfin (`services.jellyfin` in its container) — `media.nanulab.de`
- [ ] Libraries (all point into `/slow/shared-media`):
  - [ ] Movies: `/slow/shared-media/video/movies`
  - [ ] TV Shows: `/slow/shared-media/video/shows`
  - [ ] Music: `/slow/shared-media/audio/music`
  - [ ] Audiobooks: `/slow/shared-media/audio/audiobooks`
  - [ ] Books (e-books — EPUB/PDF): `/slow/shared-media/literature/books`
- [ ] Reads *arr NFO/poster files natively
- [ ] GPU: SNB iGPU → `intel-vaapi-driver`; prod → `intel-media-driver`
- [ ] **10 users declared** (admin + 9 family, from users.nix — 2026-08-08) + library setup (1% manual)
- [ ] `media` group on shared dirs

## Client
- [ ] **LiquidFin** (App Store, free tier) — the Apple client. Document connection in README / profile page. (v1 personal choice; v2 documents alternatives: Swiftfin, Infuse, web.)

## Audiobooks (manual path)
- [ ] Drop audiobook folders into `/slow/shared-media/audio/audiobooks` → Jellyfin scan → LiquidFin plays
- [ ] Optional: Shelfarr/Livrarr watch for audiobook management (not packaged)

## Shared
- [ ] nginx user-tier vhost (frontend-media zone)
- [ ] Restic include state
