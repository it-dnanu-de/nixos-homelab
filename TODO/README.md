# TODO — Project work tracker

> Master index for the nanulab homelab. Each `NN-*/todo.md` covers one project area
> with per-service checklists. Source of truth for architecture = `OpenCode.md`.
> **Read the Project Vision in OpenCode.md first** — v1 = everything in this map,
> built fully; v2 = the fork for everyone (built after v1).

## Status legend
- `[x]` done and deployed
- `[~]` in progress / partially done
- `[ ]` pending (all in-scope for v1 — no scope cuts)

## Projects (all v1, in build order)

| # | Project | Status | Progress |
|---|---------|--------|----------|
| 01 | [Foundation](01-Foundation/todo.md) | ✅ done | flake, settings, users, secrets |
| 02 | [Storage (ZFS + disko)](02-Storage/todo.md) | ~ reformat pending | **Dell to mirror `/fast`+`/slow`** (early milestone) |
| 03 | [Networking](03-Networking/todo.md) | ✅ done | IP, firewall, DNS, WG, tunnel |
| 04 | [Mail](04-Mail/todo.md) | ✅ done + verified | SNM + Resend + hardening; mail-tester/MECSA/DANE green 2026-08-07 |
| 05 | [Identity & Access](05-Identity-Access/todo.md) | ✅ done | Authelia, WG peers, profiles |
| 06 | [Cloud Services](06-Cloud-Services/todo.md) | ✅ done | Nextcloud(+Office), Collabora, Immich, Vaultwarden |
| 07 | [Downloads & VPN](07-Downloads/todo.md) | ⬜ next | qBit, SAB, slskd, VPN-Confinement netns |
| 08 | [Arr Stack](08-Arr-Stack/todo.md) | ⬜ | Radarr/Sonarr/Lidarr/Readarr + Prowlarr + Seerr (stack LOCKED) |
| 09 | [Media Player](09-Media-Players/todo.md) | ⬜ | Jellyfin (ONLY player) + LiquidFin client |
| 10 | [Smart Home](10-Smart-Home/todo.md) | ⬜ | Home Assistant (in v1) |
| 11 | [Monitoring & Backups](11-Monitoring-Backups/todo.md) | ⬜ | Beszel, Restic→B2, postgres dumps |
| 12 | [Websites](12-Websites/todo.md) | ⬜ | Hugo (v1 only — NOT in v2) |
| 13 | [Deployment](13-Deployment/todo.md) | ~ partial | runbook, 1% manual |
| 14 | [Verification](14-Verification/todo.md) | ~ partial | §13 suite (target: fully green = v1 done) |
| 15 | [v2 Backlog](15-v2-Backlog/todo.md) | ⬜ v2 only | fork + installer + general polish (NOT v1) |

## Next milestone
**Storage reformat (02)** — reformat the Dell to mirror `/fast` + `/slow` so the
prod-switch contract holds (only disko + hardware-config + zfsArcMax change).
Then the media pipeline: **Downloads & VPN (07) → Arr Stack (08) → Media Players (09)**.

## Cross-cutting open items (blockers / manual)
- [ ] **IPv6 inbound/outbound through Speedport** — AAAA published + resolving but v6 conns time out (internet.nl mail 61% / dnanu 90% fail only on IPv6). 1% manual router pass-through (OpenCode.md §3.5)
- [ ] iza / kerem / hannah MACs still `TODO` in `users.nix` (blocks Kea reservations)
- [ ] Declarative account creation (occ/CLI oneshots, idempotent) — design + build across services (OpenCode.md vision)
- [ ] Switch dumitru iPhone off manual `10.0.0.3` → DHCP (Kea hands out `10.0.0.10`)
- [ ] Re-scan ALL WireGuard QRs post-v4 deploy (deployed gen is v2 `10.0.1.x`)
- [ ] Distribute Authelia passwords (10 users)
- [ ] Publish DS records at DENIC registrar (DNSSEC §3.7) — activates DANE (TLSA `3 1 1` already published + matching)
- [ ] Flip DMARC `p=quarantine` → `p=reject` after 30 clean days
- [ ] `sshPubKey` placeholder in `settings.nix` — replace with real human key
- [ ] Prod migration: new hardware-configuration.nix + disko (2 pools) when hardware arrives (contract: only 3 files change)
