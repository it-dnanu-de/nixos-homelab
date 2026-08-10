# Network addressing — v5 plan (2026-08-08, container-tiered /16)

Human-authored addressing authority. Referenced by `users.nix`, `settings.nix`, and the container zone config (OpenCode.md §3.1).

## LAN scheme — `10.0.0.0/16` (router LAN expanded to /16 — 1% manual)

| Block | Zone | Contents | Reachability |
|---|---|---|---|
| `10.0.0.0/24` | core | `.1` router, `.2` host (ZFS/WG/container runtime), `.3-.254` spare | host |
| `10.0.10.0/24` | system/ops | nginx, mail, AdGuard, Kea, Authelia, ddclient, cloudflared, restic, Glance, Beszel | nginx + admin |
| `10.0.20.0/24` | backend-cloud | PostgreSQL, Redis, MariaDB, Collabora | **host-side (no LAN IP)** |
| `10.0.30.0/24` | frontend-cloud | Nextcloud, Immich, Vaultwarden, HA | macvlan, via nginx |
| `10.0.40.0/24` | backend-media | Sonarr, Radarr, Lidarr, Readarr, Livrarr, Prowlarr | **host-side (no LAN IP)** |
| `10.0.50.0/24` | frontend-media | Jellyfin, Seerr, Mixarr, Shelfarr | macvlan, via nginx |
| `10.0.60.0/24` | IoT | TV, Air, Xbox, smart devices | isolated; only HA reaches it |
| `10.0.70.0/24` | users LAN | family devices (blocks below) | normal LAN |
| `10.0.80.0/24` | users VPN | WireGuard peers (v5) | via WG |
| `10.0.90.0/24` | guests | DHCP pool (DNS-only) | isolated |

## Users (LAN 10.0.70.x / VPN 10.0.80.x — v4 blocks mirrored)

Each user owns a 10-IP block: base = `[user]` (no number, the primary device / Authelia login), then `[user]1` … `[user]9`.

| user | base LAN | base VPN | real devices |
|---|---|---|---|
| admin | 10.0.70.0-9 | 10.0.80.0-9 | admin3=Arch (`2c:9c:58:60:c8:25`); admin4-9 spare |
| dumitru | 10.0.70.10 | 10.0.80.10 | dumitru=iPhone (`f6:5b:6b:f3:0e:87`) |
| adela | 10.0.70.20 | 10.0.80.20 | adela=iPhone (`fe:02:26:df:0c:50`); TV+Air → IoT |
| tiberiu | 10.0.70.30 | 10.0.80.30 | tiberiu=Galaxy (`da:08:7b:fe:cf:d7`) |
| david | 10.0.70.40 | 10.0.80.40 | david=iPhone (`76:6f:b2:93:10:ce`); Xbox → IoT |
| ramona | 10.0.70.50 | 10.0.80.50 | ramona=iPhone (`56:ea:b4:79:06:61`) |
| tibisor | 10.0.70.60 | 10.0.80.60 | tibisor=iPhone (`26:05:a5:6c:e2:56`) |
| iza | 10.0.70.70 | 10.0.80.70 | all TBS |
| kerem | 10.0.70.80 | 10.0.80.80 | all TBS |
| hannah | 10.0.70.90 | 10.0.80.90 | all TBS |

VPN naming: `[user]-vpn` (base) + `[user]1-vpn` … `[user]9-vpn`. Base hostname `[user]` = Authelia login.
**Full pre-provision:** ALL slots get real WG keypairs + QRs — 7 admin peers (admin3-vpn..admin9-vpn) + 90 user peers = **97 WG peers, 194 sops keys**. Spare slots: MAC=TODO, IP reserved, QR rendered.
MACs confirmed: adela1 TV = `00:c3:f4:ea:fe:a6`, david1 Xbox = `c4:9d:ed:c9:9a:13` — **moved to IoT block (10.0.60.x)** per 2026-08-08 ruling.

## Guests
`10.0.90.0/24`, Kea DHCP pool `.100-.200`, DNS-only, no services, no VPN. `.201-.254` unassigned.

## Zone isolation (2026-08-08)
Default-deny nftables between zones; explicit allows only (frontends→their backend, backends→their DB, HA→IoT, nginx→all). Backends + DBs host-side (no LAN IP). Only nginx + frontends get macvlan LAN presence. **nginx = single ingress.**
