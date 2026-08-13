# Changes.md — temporary session log (wiped into OpenCode.md at end of session)

## 2026-08-08 — Auth direction: Authentik replaces Authelia + user-provisioning design

### Decision (human-driven)
- **Authentik replaces Authelia** as the IdP (accept heavier RAM on the Dell; prod 64GB solves it). Via `nix-community/authentik-nix` flake (no `services.authentik` in pinned 26.05).
- Provides: self-service signup + one-time invites, admin webUI (users/groups/roles/service access), **full OIDC SSO** (Nextcloud/Vaultwarden/HA/Jellyfin/Glance/arrs), password reset + recovery email.
- **users.nix drives Authentik declaratively via blueprints** (YAML users/groups/flows/providers).
- **Username = first.last** (e.g. dumitru.nanu); email = username@dnanu.de; admin stays 'admin'. Dedicated rename milestone.
- **Profile/WG-QR page lives inside Authentik**; `.mobileconfig` generator **dropped** (Nextcloud app for mail/cal on both platforms).
- **Password model:** one password per user, self-set (Authentik signup/reset); per-service hashes in sops; Vaultwarden/Jellyfin/HA via provisioning API.
- **HA only for family-tier** users (at home).
- Devices/MACs still admin-managed in users.nix (MAC = LAN/DHCP; WG uses its own keys).
- Docs updated: OpenCode.md (vision, §3.1, §3.3, §9, §10, §12), TODO 05.

---
(previous session history preserved below)

## 2026-08-08 — Full .md sweep for the container architecture

Brought every markdown file in line with the 2026-08-08 container/zone ruling:
- **docs/network-addressing.md** — rewritten to v5 (/16 zones, users LAN .70, users VPN .80, IoT .60, guests .90)
- **AGENTS.md** — rule 3: Docker → NixOS containers
- **deployment skill** — 10.0.0.2/16, container zones, updated 1% manual
- **nixos-flake skill** — native-only → all-containers; build order updated
- **sops-secrets skill** — booklore removed, mail_<user> added
- **TODO 03** — /16 base, zone isolation, WG v5 renumber
- **TODO 08/09** — Docker → NixOS containers (zones .40/.50)
- **TODO 01/14** — subnet refs updated
- **OpenCode.md** — P2P AllowedIPs → 10.0.0.0/16

---
(previous session history preserved below)

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

## 2026-08-08 — Model set refresh (from OpenRouter benchmarks via MCP)

Pulled Artificial-Analysis (intelligence/coding/agentic) + Design-Arena (ELO) via the openrouter MCP. New per-role defaults:
- architect = claude-opus-5 (63.1 intel / 78 cod / 59.2 agent — #1 everywhere)
- reviewer = kimi-k3 (59.7 intel, 1453 ELO — top design/reasoning)
- troubleshooter = qwen3.8-max (58.4 agentic — best agentic-per-dollar)
- builder = gpt-5.6-terra (76.7 cod at $1/$6 — coding value king)
- deployer = deepseek-v4-pro (kept)
- verifier = deepseek-v4-flash (kept — 69.1 cod / 48.4 agent at $0.14/$0.28)
- JOAT = qwen3.7-flash (cheapest, 1M ctx)
- NEW designer agent = muse-spark-1.2 (top-3 in all design categories)
Dropped: GLM 5.2 (troubleshooter), Nemotron (weak per benchmark).

## 2026-08-08 — Memory layer design + multimodal confirmation

- Memory: pgvector RAG on the ARCH dev machine (local Postgres + pgvector, Ollama + nomic-embed-text, memory MCP server — AtomicMemory candidate). Set up now, activated when the human starts building.
- Ingest surface: OpenCode.md, README, AGENTS, Changes.md, Memory.md, TODO/, git history. Retrieve-on-demand to minimize context.
- Multimodal confirmed via OpenRouter MCP list-models: Opus5/K3/Terra/Qwen3.8/Qwen3.7/Muse accept image input; verifier+deployer text-only; Muse Spark most capable. OpenRouter has ZERO embedding models (verified) -> local Ollama required for RAG.
- OpenRouter MCP tools discovered: list-models, get-model, list-benchmarks, generate-image, transcribe-audio, generate-speech, get-credits, send-message.

## 2026-08-08 — Memory layer LIVE: engram installed + wired into opencode

- **engram v1.20.0** (single Go binary + SQLite, no Docker/Postgres/Node) installed on Arch dev machine
- `engram setup opencode` → plugin at ~/.config/opencode/plugins/engram.ts + MCP stdio
- **Connected** in `opencode mcp list` (engram ✓)
- Seeded 9 core project-knowledge entries: vision, architecture, auth, media stack, users, email rule, monitoring, models, open issues
- Agents now save + retrieve memory (FTS keyword) — token-minimizing, replaces loading Memory.md whole
- DB: ~/.engram/engram.db (248K). Upgrade path to vector RAG: OpenRouter nemotron-3-embed-1b:free embeddings

## 2026-08-08 — Cloud plan v2: Nextcloud = self-hosted iCloud (drop Immich + Vaultwarden)

- **Nextcloud becomes the ENTIRE cloud** (2026-08-08). One Authentik login → invite → native iOS/Android clients (IMAP/CalDAV/CardDAV/WebDAV) → iCloud-style launcher (user-facing tiles, separate from Glance admin dashboard).
- **Drop Immich + Vaultwarden** entirely. Photos → Nextcloud **Memories** (v8.1.0), Passwords → Nextcloud **Passwords** (nightly). Both NOT in nixpkgs — **package via `fetchNextcloudApp`** (1 small expr each, verified on app store). Notes → packaged. Talk (`spreed`) REVISITED — calls need TURN+ports, decision pending.
- No mobileconfig — native iOS/Android apps connect directly.
- Docs: OpenCode.md vision + service map + §7 secrets + §11 backups; TODO 06 rewritten; sops: vaultwarden_admin_token removed.
- Cloudreve evaluated + rejected (duplicates Nextcloud; no CalDAV/CardDAV).

## 2026-08-12 — 3-pool storage (work/fast/slow) + directory structure v2

- **Prod hardware locked** (2026-08-12, ~€2,415): Minisforum MS-01 + 32GB DDR5 + 3 pools: /work=2×1TB NVMe RAID1, /fast=2×2TB SSD RAID1, /slow=2×4TB HDD RAID1 (TerraMaster USB DAS). Boot = 250GB NVMe.
- **Directory structure v2** (from Claude + human): /work/shared/{library,templates,projects/<name>/{00-05_}} for active creative work (raw media = source of truth, per-app project-files, exports/interchange); /fast/users/<user>/{notes,photos,documents,paperless} (filesystem = user files; Nextcloud data + Memories index here); /slow media library + downloads. Removed: user/hey, immich, per-OS subdirs, archive tier.
- **Storage policy:** no archive — Restic = version history; finished project → delete processed/, move raw/ to cold storage.
- **Client access: WebDAV only** (2026-08-12).
- Dell test box: rpool/{work,fast,slow} datasets mirror the 3 pools (same mountpoints).
- Updated: OpenCode.md §2/§5, settings.nix paths (+/work), storage-layout.nix, disko.nix (work dataset). No system rebuild.

## 2026-08-12 — Nextcloud moves to podman AIO (EuroOffice); everything else stays native

- **Nextcloud → declarative podman container** (oci-containers backend=podman). Reason (verified): nixpkgs module is 2 majors behind (32 vs 34), and EuroOffice/Memories/Passwords are NOT packageable in nix — EuroOffice only exists as an AIO container (ghcr.io/euro-office/documentserver v9.3.2, confirmed in AIO v13.4.1). Replaces Collabora.
- **Everything else stays native NixOS containers** — Jellyfin 10.11.11 + Sonarr/Radarr/Lidarr/Prowlarr are CURRENT in pinned 26.05 (verified), so no benefit to containerizing them.
- Nextcloud AIO = mastercontainer + postgres + redis + apache + eurooffice (+ optional talk/collab). Declared via Nix (pinned images, sops env), not compose.
- Docs: container model amended, cloud table (EuroOffice), service map (Nextcloud=podman, Collabora dropped), backlog. Removed stale Vaultwarden refs.

## 2026-08-12 — Corrected: Livrarr/Shelfarr/Mixarr are NOT NixOS modules (podman containers)

- Verified against pinned 26.05: only Readarr/Sonarr/Radarr/Lidarr/Prowlarr/Seerr have native modules+packages.
- Livrarr, Shelfarr, Mixarr have NO nixos module AND NO package — they must run as podman containers (GitHub-release images).
- Container model updated: 3 tiers — (1) NixOS modules in NixOS containers, (2) podman for Nextcloud AIO+EuroOffice, (3) podman for Livrarr/Shelfarr/Mixarr.

## 2026-08-12 — Media stack moved to podman (full list locked)

Human ruling: the ENTIRE media stack runs in podman (uniformity), even though
Jellyfin/Sonarr/Radarr/Lidarr/Readarr/Prowlarr/Seerr have current native Nix modules.

Final placement:
- NixOS modules (in NixOS containers): Nginx, AdGuard, Kea, ddclient, cloudflared, CF DNS sync, Mail(SNM), Authentik, HA, Glance, Beszel, Restic, PostgreSQL, Redis, VPN-Confinement
- Podman: Nextcloud AIO+EuroOffice, Jellyfin, Prowlarr, Radarr, Sonarr, Lidarr, Readarr, Seerr, qBittorrent, SABnzbd, slskd, Livrarr, Shelfarr, Mixarr
- Host: WireGuard, ZFS, container runtime
Docs updated (container model + media stack table + service map rows).

## 2026-08-12 — Decision: package Livrarr/Shelfarr/Mixarr, media stack stays NixOS modules

Criterion: "whatever declares itself better" → NixOS modules are more declarative than podman.
- Media stack = NixOS modules (Jellyfin, Prowlarr, Radarr, Sonarr, Lidarr, Readarr, Seerr, qBit, SAB, slskd) — all current in 26.05.
- Package the trio by us: Livrarr (Rust), Shelfarr (Ruby), Mixarr (TypeScript) — follow nixpkgs servarr pattern. Part of media milestone.
- Only Nextcloud AIO remains podman (EuroOffice justification).

## 2026-08-12 — Final pre-merge sweep: repo aligned with locked architecture

Removed obsolete modules: authelia.nix, collabora.nix, immich.nix, vaultwarden.nix (dropped services). Deleted from configuration.nix imports. nextcloud.nix rewritten as podman-AIO build target.

Fixed /16 + WG v5 across the codebase:
- settings.nix: prefixLength 16, subnet 10.0.0.0/16, WG subnet 10.0.80.0/24 + address 10.0.80.2
- users.nix: userToIps → .70 LAN / .80 VPN, guests → .90.100-.200
- wireguard.nix: DNS 10.0.10.2, AllowedIPs 10.0.0.0/16
- base.nix: firewall -s 10.0.0.0/16 (was /24), zone-isolation TODO
- adguard.nix: infra id 10.0.80.2, rewrite-target note
- sops.nix: removed authelia_*/mobileca_*, added authentik_* + nextcloud_aio_env
- secrets.yaml: removed authelia_*/mobileca_* keys

Docs/skills/todos aligned: security-hardening port table (10.0.10.11 mail, 10.0.10.5 nginx), verification @10.0.10.2 + media vhosts + zone isolation, zfs-disko 3 pools + v2 tree, sops-secrets inventory, deployment 1% manual, nixos-flake build order, network-addressing zones, TODO 06/08/README, README cloud description.

This is the DEFINITION phase: docs describe the target, modules are the build targets with TODO(build) markers. Builder implements the container/podman architecture next.
