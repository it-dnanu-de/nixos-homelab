# Changes.md — temporary session log (wiped into OpenCode.md at end of session)

## 2026-08-08 — Architecture ruling: all services as NixOS containers + /16 zone scheme

### Major architecture change (human-driven, reverses native-modules-on-host)
- **All services → NixOS containers** (`containers.<name>`, systemd-nspawn). Host = bare core (ZFS, kernel WG, container runtime). Docker/oci-containers model **retired**.
- **Network zones (/16):** `.10` system/ops (nginx, mail, AdGuard, Kea, Authelia, ddclient, cloudflared, restic, Glance, Beszel), `.20` backend-cloud (Postgres, Redis, MariaDB, Collabora), `.30` frontend-cloud (Nextcloud, Immich, Vaultwarden, HA), `.40` backend-media (arrs, Prowlarr), `.50` frontend-media (Jellyfin, Seerr, Mixarr, Shelfarr), `.60` IoT, `.70` users LAN, `.80` users VPN (WG v5), `.90` guests.
- **Real zone isolation:** nftables default-deny between zones; explicit allows. Backends + DBs host-side (no LAN IP, unreachable from user devices). Only nginx + frontends get macvlan. **nginx = single ingress.**
- **WG v5:** clients 10.0.10.x → 10.0.80.x; AllowedIPs → 10.0.0.0/16; server-routed P2P; QR re-render.
- **User devices** → 10.0.70.x (v4 blocks mirrored); TV/Air/Xbox → IoT (.60); guests → .90.
- slskd **confirmed in** stack (was optional).
- Router LAN → /16 (1% manual).
- Docs updated: OpenCode.md vision, §1 rules, §3.1/3.2/3.3, §9 service map (zones), §13 verification.
- **Formal build plan: architect** (after merge/restart when new agents are live).

---
(previous session history preserved below)

## 2026-08-08 — Second definition pass (round 2 audit)

### Decisions locked (human answers)
- **users.nix = single source of truth for ALL services** (identity + email + per-service provisioning)
- **11 mailboxes**: hey@, admin@, + 9 family (`<user>@dnanu.de`). Separate mailboxes per user. All 10 users provisioned on everything ("mail is not user-choice"). Current alias set kept.
- **Email rule**: no server-initiated ALERT emails to hey@; transactional emails (Vaultwarden reset, Nextcloud shares) stay via postfix→Resend, From `app@dnanu.de`
- **Glance dashboard** (`services.glance`, status.nanulab.de, admin-only) replaces email alerts; Beszel monitors everything; mail-queue-watch → status file → Glance
- **Media vhosts**: media/tv/music/books.nanulab.de (user-facing) + [service].nanulab.de backends (admin-only); split-horizon DNS only
- **WireGuard server-routed P2P**: AllowedIPs + 10.0.10.0/24, wg0 forwarding
- Nextcloud `defaultapp = "dashboard"`; data on /fast/user/hey; apps = mail/calendar/contacts/richdocuments/files
- Immich stays /fast/immich, full backup (media + DB); Vaultwarden individual vaults, keep SMTP; mail on /fast/mail
- Jellyfin 10 declared users; HA 10 declared users; backups nightly 02:00 7/4/12; manual backup before reformat; full §13 after reformat

### Doc updates
- OpenCode.md: vision expanded (users/email/monitoring/media-vhosts/WG-P2P rules), §4.2 11 mailboxes, §4.5 D6 dashboard-only, §7 mail_<user>, §9 Glance + vhost URLs, §11 schedule/retention
- TODO 03/04/06/08/09/11 updated

---
(previous session history preserved below)

## 2026-08-08 — Repo definition sweep (full audit + decisions)

Complete pass over the nixos-homelab repo to make it a self-describing workspace.

### Cleanups applied
- Removed `booklore_db_password` from secrets.yaml + sops.nix (Booklore dropped)
- Removed `modules/services/.gitkeep` (dir has real modules now)
- settings.nix: comment fixes (internal = VPN-only not Tailscale; admin block .3-9; AirVPN forwardedPort note)
- storage-layout.nix: added `/fast/containers`, dropped `/slow/shared-media/audio/podcasts` (scope trimmed)
- OpenCode.md: Hugo → v2, HA half-declared (10 users), trimmed media dirs, network-addressing link, fixed §6 tree

### Decisions locked (human answers, 2026-08-08)
- slskd: keep, decide at build time
- AirVPN: still need subscription (forwardedPort stays 0)
- SSH key: no key exists on machine or server — placeholder stays (password auth enabled)
- Home Assistant: half-declared (users declared, rest via web UI); all 10 users declared
- Hugo site → **v2** (not v1)
- Beszel + restic→B2: both v1
- Container config volumes → `/fast/containers`
- All container services behind nginx vhosts (user-tier ACL)
- Server pulls main, manual deploy (no CI auto-deploy)
- docs/network-addressing.md: keep + link from OpenCode.md
- tests/: keep as §13 evidence
- MCP set: context7 + ssh-homelab + playwright (resend dropped, github disabled)

### Still open (blockers / human)
- AirVPN subscription (vpn.forwardedPort)
- SSH pubkey (none found anywhere)
- iza/kerem/hannah MACs
- DS records at DENIC, DMARC flip after 30 days, IPv6 pass-through
