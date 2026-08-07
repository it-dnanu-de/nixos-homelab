# TODO — 08 Arr Stack (media managers + requests — Docker containers)

**Status:** ⬜ not started · **Owner:** nixos-builder + architect · **Modules:** `modules/services/containers.nix` (oci-containers) or per-service modules

> Media automation: request → manager → Prowlarr → downloader → manager organizes → Jellyfin → LiquidFin.
> Stack LOCKED 2026-08-08 (see OpenCode.md Project Vision). **Managers + request services run as Docker containers** (`virtualisation.oci-containers`, backend `docker`), per human ruling. Jellyfin + Prowlarr are native modules.

## Containers to define (oci-containers, docker backend)
- [ ] **Radarr** — movies manager (image: lscr.io/linuxserver/radarr)
- [ ] **Sonarr** — TV manager (lscr.io/linuxserver/sonarr)
- [ ] **Lidarr** — music manager (lscr.io/linuxserver/lidarr)
- [ ] **Readarr** — books arr, pinned + rreading-glasses mirror (lscr.io/linuxserver/readarr)
- [ ] **Livrarr** — books/audiobooks manager (kkodecs/livrarr — NOT packaged, custom container def)
- [ ] **Seerr** — movies/TV requests (native 26.05 module exists BUT container per ruling)
- [ ] **Mixarr** — music requests (aquantumofdonuts/mixarr — NOT packaged)
- [ ] **Shelfarr** — books/audiobooks requests (Pedro-Revez-Silva/shelfarr — NOT packaged)

## Container definition pattern
- [ ] `virtualisation.oci-containers.backend = "docker"`
- [ ] Each container: pinned image digest (never `:latest`), loopback-only ports, volumes to `/slow/*` + `/fast/containers/<app>:/config`, TZ env
- [ ] **config.xml seeding**: Nix-shipped config file per app (port, url base, auth) so apps boot already-mostly-configured
- [ ] sops secrets via `environmentFiles` (or compose2nix sops integration if we go compose route)
- [ ] Optional: `compose2nix` (packaged 26.05) to generate config from a docker-compose.yml

## Vhost scheme (2026-08-08)
- [ ] **User-facing:** `media.nanulab.de`=Jellyfin, `tv.nanulab.de`=Seerr, `music.nanulab.de`=Mixarr, `books.nanulab.de`=Shelfarr (user-tier ACL)
- [ ] **Backend (admin-only):** `sonarr.nanulab.de`, `radarr.nanulab.de`, `lidarr.nanulab.de`, `readarr.nanulab.de`, `livrarr.nanulab.de`, `prowlarr.nanulab.de` (admin-tier ACL)
- [ ] DNS = split-horizon only (existing `*.nanulab.de` → 10.0.0.2 rewrite; no public records)

## Native (non-container)
- [ ] **Prowlarr** — indexer manager (`services.prowlarr`, native 26.05)
- [ ] Connect all containers to Prowlarr (1% manual — web UI once, persists in /config)
- [ ] Connect managers to qBittorrent/SABnzbd (1% manual — web UI once, persists in /config)
- [ ] Hardlink completion into `/slow/shared-media`

## Unpackaged container images (verify at build time)
- [ ] Livrarr: build/pin from `kkodecs/livrarr` GitHub releases or a container image if published
- [ ] Mixarr: `aquantumofdonuts/mixarr` — check for published container image
- [ ] Shelfarr: `Pedro-Revez-Silva/shelfarr` — check for published container image
- ⚠️ If any has no official image, we build a small container or run as a systemd service instead — flag in plan

## Shared
- [ ] Restic include of container state (bind-mounted dirs are on /slow or /fast already)
- [ ] `media` group for shared dirs
