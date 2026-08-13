# TODO — 08 Arr Stack (backend-media — NixOS modules in NixOS containers)

**Status:** ⬜ not started · **Owner:** builder + architect · **Modules:** per-service NixOS container declarations

> Media automation: request → manager → Prowlarr → downloader → manager organizes → Jellyfin → LiquidFin.
> Architecture (2026-08-12): **media stack runs as NixOS modules inside NixOS containers** (`containers.<name>`, systemd-nspawn). Backend-media zone `10.0.40.0/24` (host-side, no LAN IP). **Livrarr/Shelfarr/Mixarr are PACKAGED BY US** (they have no NixOS module — Rust/Ruby/TS respectively).

## Backend-media containers (zone .40 — host-side)
- [ ] **Radarr** — movies manager (`services.radarr`)
- [ ] **Sonarr** — TV manager (`services.sonarr`)
- [ ] **Lidarr** — music manager (`services.lidarr`)
- [ ] **Readarr** — books arr, pinned + rreading-glasses mirror (`services.readarr`)
- [ ] **Livrarr** — books/audiobooks manager — **package by us** (Rust, kkodecs/livrarr, follow nixpkgs servarr pattern)
- [ ] **Prowlarr** — indexer manager (`services.prowlarr`)

## Frontend-media containers (zone .50 — macvlan, via nginx)
- [ ] **Jellyfin** — the ONLY player (`services.jellyfin`)
- [ ] **Seerr** — movies/TV requests (`tv.nanulab.de`, `services.seerr`)
- [ ] **Mixarr** — music requests (`music.nanulab.de`) — **package by us** (TypeScript, aquantumofdonuts/mixarr)
- [ ] **Shelfarr** — books/audiobooks requests (`books.nanulab.de`) — **package by us** (Ruby, Pedro-Revez-Silva/shelfarr)

## Container pattern (NixOS containers)
- [ ] `containers.<name> = { privateNetwork = true; hostAddress = "<zone gw>"; localAddress = "<zone ip>"; }`
- [ ] Each container: its own `services.*` config, state in `/var/lib` (NixOS containers), media on `/slow`
- [ ] Backends host-side (no LAN IP); frontends macvlan
- [ ] nginx (single ingress) proxies → frontend containers; admin vhosts → backend containers
- [ ] **Users declarative:** per-service accounts via occ/CLI oneshots at first boot (from users.nix)

## Packaging the trio (Livrarr/Shelfarr/Mixarr)
- [ ] Livrarr (Rust): `kkodecs/livrarr` — package via nixpkgs servarr pattern (`pkgs/by-name/so/sonarr` as template)
- [ ] Mixarr (TS): `aquantumofdonuts/mixarr` — same
- [ ] Shelfarr (Ruby): `Pedro-Revez-Silva/shelfarr` — same
- [ ] Verify each builds + registers a `services.<name>` module

## Shared
- [ ] Zone isolation rules (frontend-media → backend-media, backend-media → downloaders, nginx → all)
- [ ] Restic include of container state
- [ ] `media` group for shared dirs
