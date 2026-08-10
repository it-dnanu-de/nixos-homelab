# TODO — 08 Arr Stack (backend-media containers)

**Status:** ⬜ not started · **Owner:** builder + architect · **Modules:** `modules/containers/*` (NixOS containers) per service

> Media automation: request → manager → Prowlarr → downloader → manager organizes → Jellyfin → LiquidFin.
> Architecture (2026-08-08): **ALL services are NixOS containers** (`containers.<name>`, systemd-nspawn). Backend-media zone `10.0.40.0/24` (host-side, no LAN IP). Docker/oci-containers retired.

## Backend-media containers (zone .40 — host-side)
- [ ] **Radarr** — movies manager
- [ ] **Sonarr** — TV manager
- [ ] **Lidarr** — music manager
- [ ] **Readarr** — books arr, pinned + rreading-glasses mirror
- [ ] **Livrarr** — books/audiobooks manager (kkodecs/livrarr — unpackaged, need nixpkgs or a container build)
- [ ] **Prowlarr** — indexer manager

## Frontend-media containers (zone .50 — macvlan, via nginx)
- [ ] **Jellyfin** — the ONLY player
- [ ] **Seerr** — movies/TV requests (`tv.nanulab.de`)
- [ ] **Mixarr** — music requests (`music.nanulab.de`, unpackaged)
- [ ] **Shelfarr** — books/audiobooks requests (`books.nanulab.de`, unpackaged)

## Container pattern (NixOS containers)
- [ ] `containers.<name> = { privateNetwork = true; hostAddress = "<zone gw>"; localAddress = "<zone ip>"; }`
- [ ] Each container: its own `services.*` config, `/fast/containers/<app>` state, media on `/slow`
- [ ] Backends host-side (no LAN IP); frontends macvlan
- [ ] nginx (single ingress) proxies → frontend containers; admin vhosts → backend containers
- [ ] **Users declarative:** per-service accounts via occ/CLI oneshots at first boot (from users.nix)

## Unpackaged (Livrarr/Mixarr/Shelfarr)
- [ ] Livrarr: `kkodecs/livrarr` — check nixpkgs presence at build (via `nixos` MCP), else package/containerize
- [ ] Mixarr: `aquantumofdonuts/mixarr` — same
- [ ] Shelfarr: `Pedro-Revez-Silva/shelfarr` — same
- ⚠️ If any has no package, build a small NixOS container from source or flag in plan

## Shared
- [ ] Zone isolation rules (frontend-media → backend-media, backend-media → downloaders, nginx → all)
- [ ] Restic include of container state
- [ ] `media` group for shared dirs
