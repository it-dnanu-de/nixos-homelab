# TODO — 08 Arr Stack

**Status:** ⬜ not started · **Owner:** nixos-builder · **Modules:** `modules/services/arr-stack.nix`

> Media automation: request → *arr → indexer → downloader → *arr manages → Jellyfin → LiquidFin.
> Stack LOCKED 2026-08-08 (see OpenCode.md Project Vision). All native `services.<name>` modules in pinned 26.05.

## Media stack (LOCKED — one player, few services)
| Media | Request | Manager | Indexer | Downloader | Player | Client |
|---|---|---|---|---|---|---|
| Movies | Seerr | **Radarr** | Prowlarr | qBit/SAB | Jellyfin | LiquidFin |
| TV Shows | Seerr | **Sonarr** | Prowlarr | qBit/SAB | Jellyfin | LiquidFin |
| Music | undecided* | **Lidarr** | Prowlarr | qBit/SAB | Jellyfin | LiquidFin |
| Books | undecided* | **Readarr** | Prowlarr | qBit/SAB | Jellyfin | LiquidFin |
| Audiobooks | — (manual) | — (manual) | — | manual | Jellyfin | LiquidFin |
| Podcasts | **dropped** | — | — | — | — | — |

\* Mixarr (150★), Livrarr (20★), Shelfarr (276★) are real but **NOT in nixpkgs** — declarability decision deferred.

## Managers (native modules)
- [ ] **Sonarr** — TV: NFO + poster → Jellyfin
- [ ] **Radarr** — Movies: NFO + poster → Jellyfin
- [ ] **Lidarr** — Music: organizes → Jellyfin reads tags
- [ ] **Readarr** ⚠️ archived upstream — pin package, metadata API → `rreading-glasses` mirror; migration note in README
- [ ] **Prowlarr** — indexer manager, shared across all arrs
- [ ] Connect all arrs to qBittorrent/SABnzbd (1% manual)
- [ ] Prowlarr indexers (1% manual)
- [ ] Hardlink completion into `/slow/shared-media`

## Requests
- [ ] **Seerr** (`services.seerr`, pinned 26.05 ✅) — `requests.nanulab.de` (VPN-only)
- [ ] Connect Seerr → Sonarr/Radarr (+ Jellyfin via LiquidFin's built-in Jellyseerr)
- [ ] Music/books requests: undecided (Mixarr/Shelfarr not packaged) — defer to later decision

## Dropped (2026-08-08)
- 🗑 Bazarr (no subtitle layer) · beets (no tag post-processor) · soularr (no slskd bridge) · Kometa (no Plex)
- slskd: optional music downloader — keep only if we want Lidarr→slskd for missing albums

## Shared
- [ ] nginx vhosts: `*.nanulab.de` per service (user-tier ACL)
- [ ] Restic include of app state
