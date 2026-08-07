# OpenCode.md — nanulab/dnanu 20-Year NixOS Homelab

> **This document is the single source of truth.** Build exactly what is specified here.
> Choices marked ✅ LOCKED are decided — do not revisit them.
> Choices marked ⚠️ VERIFY must be checked against pinned `nixos-26.05` before use.
> All options, packages, and module names reflect the pinned channel (`nixos-26.05`).
> Do not add services, containers, or dependencies not listed here.
> Repo is public-safe. Secrets live in `secrets/secrets.yaml` (sops) and `Memory.md` (gitignored).

## Project Vision (read this first)

**Three repos:**
1. `it-dnanu-de/nixos` — **abandoned** (archive, pre-restructure).
2. `it-dnanu-de/nixos-homelab` — **v1**: the opinionated PERSONAL homelab. Built fully, start to finish. Made **private** when v2 forks off.
3. **v2** — a fork of v1, generalized so anyone can clone and customize. Public. Name decided at fork time.

**The plan:** build v1 completely → private the v1 repo → fork v2 → build the installer + general polish in v2. Nothing else matters until v1 is done.

**v1 = everything, no scope cuts.** Every service in the §9 service map is built, verified, backed up, and documented. The media pipeline is the heart of the project. **v1 is done when:** all service-map services deployed + verified on the Dell, restic backing up, §13 suite fully green, docs current, and the repo shaped so v2 is a fork + scrub.

**v2 scope (for everyone):** the general template + the `install.sh` (fork → GitHub repo → interactive Q&A → generate config → print manual steps). **The website/blog is NOT in v2** (many people don't host blogs) — v2 documents how to add your own blog. Hugo stays a v1 personal add-on.

**Media pipeline pattern** — the same story for every media type:
`request service → *arr → indexer → downloader → *arr manages → player → client app`

**Media stack — ✅ LOCKED (2026-08-08):**
| Role | Choice |
|---|---|
| Client | **LiquidFin** (Apple: iPhone/iPad/Mac/Apple TV/Watch; movies/TV/music/audiobooks/books; offline downloads; Jellyseerr built-in) |
| Player | **Jellyfin** (the ONLY player — movies, TV, music, audiobooks, books) |
| Movies manager | **Radarr** |
| TV manager | **Sonarr** |
| Music manager | **Lidarr** |
| Books manager | **Readarr** (pinned + rreading-glasses mirror) |
| Indexer manager | **Prowlarr** |
| Downloaders | **qBittorrent + SABnzbd** (+ optional slskd for music), all VPN-confined |
| Requests | **Seerr** (native 26.05 module; merged project covering Plex/Jellyfin/Emby) for movies+TV |
| Audiobooks | **manual** (no good arr exists; drop files into Jellyfin audiobook library) |
| Podcasts | **dropped** |
| Comics/manga | **dropped** (e-books only) |
| Music requests / book+audiobook managers | **undecided** — Mixarr (150★), Livrarr (20★), Shelfarr (276★) are real but NOT in nixpkgs; decision deferred, see TODO 08 |
| beets / Bazarr / soularr / slskd | **dropped** (no separate metadata/tagging layer; the arrs manage + Jellyfin reads tags) |

Rules: **one player (Jellyfin), one client (LiquidFin, personal v1 choice; v2 server stays client-agnostic)**. "Fewer services is better." The arrs are the file managers — no separate organizer. Podcasts and comics/manga are out of scope.

**v1 in-scope (all media types):** movies + TV (Seerr → Radarr/Sonarr → Prowlarr → qBittorrent/SABnzbd → Jellyfin → LiquidFin), music (Lidarr → Prowlarr → downloaders → Jellyfin → LiquidFin), audiobooks (manual → Jellyfin → LiquidFin), books (Readarr → Prowlarr → downloaders → Jellyfin → LiquidFin). Plus Home Assistant, Beszel, restic→B2, Hugo (v1 only), and the `.mobileconfig` generator.

**Core rules:**
- **Native modules preferred; containers allowed when justified** (media apps, Booklore). "Zero containers" was a phase-1 simplification; it is retired.
- Downloader VPN isolation via **VPN-Confinement network namespaces** (AirVPN).
- **Prod switch = change only `disko.nix` + `hardware-configuration.nix` + `zfsArcMax` in settings.nix.** Everything else identical. The Dell is reformatted early in v1 to mirror `/fast` + `/slow` so this contract holds.
- **Accounts are declarative** — created via occ/CLI oneshots on first install (idempotent), not web UI.
- Data lives in DBs (postgres/sqlite) + `/fast`, backed up nightly via restic. Accounts persist across rebuilds (verified).
- Verification per change: CI flake check + targeted smoke. Full §13 suite after milestones.
- Docs ship in the same PR as the code they describe. English only.
- Workflow: delegate → feature branch → PR → human merges → server pulls main. Checkpoint per milestone.

## 1. Philosophy & Hard Rules

1. **99% Declarative Rule.** NixOS declares infrastructure: ZFS, networking, services, users, paths, secrets, TLS. The human configures application *state* once via web UIs (admin accounts, indexers, libraries). No bootstrap scripts poking APIs — they rot.
2. **Native NixOS modules preferred; containers allowed when justified.** Phase-1 "zero containers" is retired. Media apps and exceptions (e.g. Booklore) may run as containers/podman when a native module is missing or inadequate. VPN isolation always uses `VPN-Confinement` namespaces, not containers.
3. **Zero open ports** except TCP 25 (inbound SMTP) + UDP 51820 (WireGuard), both forwarded to `10.0.0.2`. Everything else rides the WireGuard VPN, the Cloudflare tunnel, or a confined netns.
4. **Stable channel, pinned flake.** `nixpkgs` follows `nixos-26.05`. No auto-upgrades. Human runs `nix flake update` deliberately, 2–4×/year.
5. **Single-node monolith.** No clustering.
6. **Single-user system.** One human. One mailbox identity (`hey@dnanu.de`), one services admin (`admin@dnanu.de`).
7. **Secrets via `sops-nix` (age).** Private age key lives on a USB drive + password manager, never in the repo. Repo is public-safe.
8. **SSH password auth stays enabled** — intentional human ruling. Keys are fine in addition.

## 2. Hardware Lifecycle

| Phase | Machine | CPU/RAM | Disk |
|-------|---------|---------|------|
| Test | Dell Latitude E5520 | i5-2520M / 6GB DDR3 | 250GB SSD, single-disk ZFS |
| Prod | Future build | 12th-gen i5 / 64GB | 1TB NVMe boot, 2×4TB SSD RAID1 (`fast`), 2×8TB HDD RAID1 (`slow`) |

**Migration contract:** the config references abstract paths `/fast` and `/slow` via `settings.nix` only. Moving to prod = new `hardware-configuration.nix`, new `disko.nix` (two pools, same mountpoints), bump `zfsArcMax`. Nothing else changes.

Dell-specific: `services.logind.lidSwitch = "ignore"` (lid closed ≠ suspend — the battery is a free UPS). Immich machine learning **disabled** on this CPU.

## 3. Network Architecture

### 3.1 Topology
- Router: Telekom Speedport Smart 4 @ `10.0.0.1`. **DHCPv4 must be disabled** (DHCPv6 disabled-if-possible, else harmless coexistence — Kea serves only ULA). IPv6 stays on (mail + modern infra need it — §3.5).
- Server: **static** `10.0.0.2/24`, gw `10.0.0.1`, ULA `fd10::2/64`, declared in NixOS. No ARP tricks.
- **v4 user-block addressing (2026-08-06):** `users.nix` is the single source of truth for IP allocation. Blocks: admin (0-9; admin0=net addr, admin1=router, admin2=homelab=WG server, admin3-9=devices), dumitru (.10-19), adela (.20-29), tiberiu (.30-39), david (.40-49), ramona (.50-59), tibisor (.60-69), iza (.70-79), kerem (.80-89), hannah (.90-99). Naming: base=[user] (no number), then [user]1-9. Guests (.100-200, Kea DHCP pool, no VPN), .201-.254 unassigned.
- **Kea** (`services.kea.dhcp4` + `services.kea.dhcp6`) is the LAN DHCP server. AdGuard Home is **DNS-only**. Kea dhcp4: pool `.100-.200`, 10 host reservations (real MACs only). Kea dhcp6: stateful ULA `fd10::/64`, pool `fd10::100-200`, DNS = `fd10::2`. GUA via Speedport SLAAC (accept_ra=1, no v6 forwarding). Server static ULA `fd10::2/64`.

### 3.2 Ports & Exposure — ✅ LOCKED

| Flow | Path | Ports open on router |
|------|------|----------------------|
| Inbound SMTP (server→server) | Internet → `mail.dnanu.de` (public A, **grey cloud**, ddclient-updated) → router fwd → `10.0.0.2:25` | **25/tcp** |
| Public blogs + autoconfig | Internet → Cloudflare edge → `cloudflared` tunnel → nginx `10.0.0.2:8080` | none |
| Remote access (all devices) | Internet → `vpn.dnanu.de` (grey cloud, ddclient) → router fwd UDP 51820 → `10.0.0.2:51820` (WireGuard) | **51820/udp** |
| Everything else (Nextcloud, Jellyfin, IMAP 993, submission 465, all admin UIs) | Device → WireGuard tunnel → `10.0.0.2` (nginx 443 / mail 993+465 / admin UIs) | none |
| Outbound mail | Postfix → `smtp.resend.com:465` (SMTPS, user `resend`, pass = API key) | none |
| Torrent/Soulseek/Usenet | confined netns → AirVPN WireGuard | none |

Router column total: **25/tcp + 51820/udp only**.

**Host firewall** (audit Finding 1, 2026-08-07): only 25/tcp + 51820/udp globally open; 53/80/443/465/587/993 source-scoped to LAN/ULA/link-local (iptables extraCommands). No service port is publicly reachable through the host.

### 3.3 WireGuard — remote-access VPN — ✅ LOCKED (2026-08-05, supersedes Tailscale SaaS; v4 2026-08-06)
- Kernel WireGuard, `networking.wireguard.interfaces.wg0`, server `10.0.10.2/24` (mirroring LAN 10.0.0.2). No SaaS control plane. **No exit node** (split-tunnel only) — kills the WhatsApp/adguard-reachability/blocking-rate issues.
- **97 peers fully pre-provisioned** (7 admin admin3-9-vpn + 90 user [user]+[user]1-9-vpn) with real keypairs. Spare slots: MAC=TODO, QR pre-rendered; claim = fill MAC + rebuild. Peers derived from `users.nix` helpers (wgPeers/wgPeerNames). Public keys in generated `wireguard-pubkeys.nix` (97 entries, committed). Private keys + PSKs in sops (`wireguard_peer_<hostname>-vpn_{private,psk}`, **194 keys**). Keygen via `scripts/gen-wg-keys.sh` (idempotent).
- Endpoint `vpn.dnanu.de` (grey cloud, ddclient-managed) — router forwards **UDP 51820 → 10.0.0.2**. WireGuard silently drops unauthenticated packets: the port answers no scans; no TLS/HTTP/control-plane surface exists.
- Client configs push `DNS = 10.0.0.2` and `AllowedIPs = 10.0.0.0/24`: all DNS flows through the tunnel to AdGuard (per-device labels via static 10.0.10.x ids), internet traffic stays direct.
- Reachability split: `*.nanulab.de` service vhosts are **VPN-only** (nginx source allowlist derived from `users.nix` — admin LAN 10.0.0.1-9 + VPN 10.0.10.3-9, user LAN 10.0.0.10-99 + VPN 10.0.10.3-99). AdGuard UI is admin-tier (admin LAN/VPN only). `profile.dnanu.de` is reachable over LAN/WiFi **without VPN** (cloudflared tunnel + Authelia).
- Onboarding: activation oneshot (`wireguard-profile-render`) renders per-user `.conf` + QR PNGs → `/var/lib/mobileprofile/wg/<user>/`; served at `profile.dnanu.de/<user>/` behind Authelia. iOS = official WireGuard app → scan QR → enable On-Demand (WiFi+Cellular) once. No accounts — possession of the private key IS identity. Admin page shows 7 QRs (admin3-9-vpn), user pages show 10 QRs (all slots).
- Fallback: headscale + headplane (both native modules, verified in pinned 26.05) if self-service multi-device enrollment is ever needed — §15.

### 3.4 Split-Horizon DNS — ✅ LOCKED (this is what makes iOS work)
- **AdGuard DNS rewrites** (declarative, `mutableSettings = false`):
  - `*.nanulab.de` → `10.0.0.2`
  - `mail.dnanu.de` → `10.0.0.2`
  - everything else → upstream (quad9)
- Public Cloudflare DNS:
  - `*.nanulab.de` / bare `nanulab.de` → **no public A records** (services are VPN-only; resolving publicly leaks internal naming and reaches nothing). AdGuard rewrites serve LAN/VPN clients locally.
  - `vpn.dnanu.de` A → dynamic home IP (grey cloud, ddclient). WireGuard endpoint.
  - `mail.dnanu.de` A → dynamic home IP (grey cloud, ddclient). **Must stay unproxied or SMTP dies.**
- Result: on VPN or LAN, `mail.dnanu.de`/`*.nanulab.de` hit `10.0.0.2` directly; off VPN, only `:25` exists. iOS Mail syncs when WireGuard is on — accepted behavior.
- AdGuard UI (`adguard.nanulab.de`) is **admin-IP-only** (nginx allowlist: 10.0.0.1-9 + 10.0.10.3-9). All LAN/VPN devices use AdGuard as DNS on :53 irrespective of tier.
- **Dead-name handling:** `*.nanulab.de` wildcard rewrite kept. nginx catch-all `default_server` on 0.0.0.0:443+:80 returns **404** — unmatched `*.nanulab.de` hosts no longer leak the AdGuard dashboard. AGH DNS-only, `runtime_sources.dhcp=false` (Kea manages DHCP).

### 3.5 LAN IPv6
IPv6 **stays enabled** (human ruling 2026-08-05: needed for mail + modern infra; Speedport cannot disable it anyway).

- **GUA (SLAAC):** Server receives a public `2003:c8:...` GUA from the Speedport's Router Advertisements. `net.ipv6.conf.all.forwarding=0` (explicitly set in `base.nix`) ensures RAs are processed. No v6 forwarding — the server is a v6 client, not a router.
- **ULA (static):** `fd10::2/64` for Kea DHCPv6 DNS anchor (§3.1).
- **DDNS:** ddclient publishes `mail.dnanu.de` + `vpn.dnanu.de` AAAA records via ipify-ipv6 (web-based detection survives GUA renumber / privacy-extension rotation). Default `usev6` in nixpkgs 26.05.
- **Speedport:** DHCPv6 points DNS at AdGuard. GUA via SLAAC unchanged.
- **Inbound v6 mail (`:25`):** Allowed in the host firewall (inet family covers v4/v6).
- **Known gap (2026-08-07):** v6 connections to the server **time out** through the Speedport — AAAA records publish and resolve, but the router's v6 pass-through is the 1% manual step. internet.nl mail 61% / dnanu 90% fail only on IPv6 reachability. Fix = Speedport v6 pass-through in the router UI.
- **Kea DHCPv6** (stateful ULA `fd10::/64`) + Speedport DHCPv6 (GUA) coexist — disjoint address spaces, both DNS → AdGuard. Android ignores DHCPv6 → covered by v4 DNS.

### 3.6 Cloudflare Tunnel (blogs only)
`services.cloudflared.tunnels."<id>"` with `credentialsFile` from sops; ingress: `dnanu.de`, `www.dnanu.de`, `autoconfig.dnanu.de`, `mta-sts.dnanu.de` → `http://127.0.0.1:8080`, `profile.dnanu.de` → `https://127.0.0.1:443` (`originRequest.noTLSVerify=true`), default `http_status:404`. Tunnel is **config_src=local** (declarative — ingress lives in the NixOS-generated `cloudflared.yml`, never the dashboard). The account-scoped `cloudflare_account_token` (Account > Cloudflare Tunnel > Edit) in sops allows full tunnel management via API without the dashboard. **Lesson (2026-08-07):** touching a tunnel in the CF dashboard flips it to remote-managed (`config_src=cloudflare`) and cloudflared then ignores the local config file (all hostnames dead, 404). `config_src` is only settable at tunnel creation — recovery = recreate the tunnel via API with `config_src=local`, update `settings.nix` tunnelId + sops `cloudflared_tunnel_cred`, rebuild.

### 3.7 DNSSEC — ✅ LOCKED (Cloudflare-managed, zero NixOS config)
- Enable DNSSEC on both Cloudflare zones (`dnanu.de`, `nanulab.de`). Algorithm: ECDSAP256SHA256 (CF-managed). Nameservers unchanged.
- Publish the DS record (one per zone) at the `.de` registrar's DENIC interface. **1% manual**, added to §12. Order: enable signing at Cloudflare first, **then** publish DS at registrar. Never withdraw signing while DS exists.
- No conflicts: grey-cloud `mail.dnanu.de` (dynamic IP) is re-signed automatically by Cloudflare; DNSSEC signs names, not IPs. Proxied records sign fine. `*.nanulab.de` has no public records — nothing to sign there. AdGuard split-horizon rewrites are unsigned local answers (standard private-view behaviour, accepted).
- **DANE TLSA** `3 1 1` already published + matching on both zones (verified 2026-08-07); activates once DS is published at DENIC.
- Verification: `dig +dnssec +adflag dnanu.de @9.9.9.9` (AD bit set), `delv dnanu.de`, dnsviz.net spot check.

## 4. Mail Architecture

### 4.1 Stack — ✅ LOCKED
- **simple-nixos-mailserver** (Postfix + Dovecot + Rspamd): IMAP 993, submission 465 (SMTPS) + 587, LMTP, ManageSieve.
- **Nextcloud** provides CalDAV/CardDAV/WebDAV + Mail web app. Stalwart is **not** used.
- Inbound: port 25 direct. Outbound: Resend relay. No VPS relay. Accepted risk: Telekom inbound-25 flakiness → mail-queue watchdog (§4.5 D6).
- **Hardening (2026-08-06/07):** postfix helo/sender/recipient RFC-conformance restrictions; rspamd reject=12 + stock RBLs (spamhaus off — public resolver path); TLS-RPT (`mailserver.tlsrpt`) + DMARC reporting (`mailserver.dmarcReporting`) both enabled; outbound Resend path pinned to `verify` via static tls_policy ahead of tlspol; DANE TLSA 3 1 1 auto-synced from the ACME cert; queue watchdog alerts via Resend API. **Verified green:** mail-tester 0.1 (SPF/DKIM/DMARC pass), MECSA 100s (TLS/DKIM/DMARC/DANE/DNSSEC/MTA-STS), haveDANE 3/3, dnsviz Secure.

### 4.2 Accounts — ✅ LOCKED
```nix
mailserver = {
  enable = true;
  fqdn = "mail.dnanu.de";
  domains = [ "dnanu.de" ];
  enableSubmission = true;     # 587
  enableSubmissionSsl = true;  # 465
  accounts."hey@dnanu.de" = {
    hashedPasswordFile = config.sops.secrets.mail_hey.path;
    aliases = [ "it@" "health@" "wealth@" "creative@" "academic@"
                "accounts@" "contact@" "partners@" ]; # @dnanu.de
    sieveScript = '' ... per-alias fileinto :create ... '';
  };
  accounts."admin@dnanu.de" = {
    hashedPasswordFile = config.sops.secrets.mail_admin.path;
    aliases = [ "postmaster@" "hostmaster@" "webmaster@" "abuse@" "security@" ];
  };
  x509.useACMEHost = "mail.dnanu.de"; # cert from security.acme DNS-01, group-readable by dovecot/postfix
};
```
Sieve logic: `if address :is "to" "it@dnanu.de" { fileinto :create "IT"; stop; }` × 8; fallthrough → INBOX (only `hey@` lands there). Sub-addressing `hey+foo@` ✅ `recipientDelimiter` verified.

### 4.3 Outbound relay (Resend) — ✅ LOCKED
SNM has no relay option; use Postfix directly:
```nix
services.postfix = {
  mapFiles."sasl_passwd" = sopsTemplate; # "[smtp.resend.com]:465 resend:re_APIKEY" — rendered from sops, mode 0600
  # Static TLS policy — verify (CA+hostname) beats the tlspol socketmap for the relay.
  mapFiles."tls_policy" = pkgs.writeText "tls_policy" ''
    [smtp.resend.com]:465 verify
    smtp.resend.com verify
  '';
  settings.main = {
    relayhost = "[smtp.resend.com]:465";
    smtp_sasl_auth_enable = "yes";
    smtp_sasl_password_maps = "hash:/etc/postfix/sasl_passwd";
    smtp_sasl_security_options = "noanonymous";
    smtp_tls_wrappermode = "yes";
    # REMOVED: smtp_tls_security_level = "encrypt"; (per-destination TLS via tls_policy + tlspol)
    smtp_tls_policy_maps = lib.mkBefore [ "hash:/var/lib/postfix/conf/tls_policy" ];
  };
};
```

### 4.4 DNS records (Cloudflare, grey cloud unless noted)

| Type | Name | Value |
|------|------|-------|
| A | `mail.dnanu.de` | home IP (ddclient-managed) |
| AAAA | `mail.dnanu.de` | home IPv6 GUA (ddclient-managed) |
| A | `vpn.dnanu.de` | home IP (ddclient-managed, grey cloud) — WireGuard endpoint §3.3 |
| AAAA | `vpn.dnanu.de` | home IPv6 GUA (ddclient-managed — dual-stack WG endpoint) |
| MX | `dnanu.de` | `mail.dnanu.de` prio 10 |
| MX | `nanulab.de` | `mail.dnanu.de` prio 10 |
| TXT | `dnanu.de` | `v=spf1 -all` (nothing sends with envelope @dnanu.de; Resend uses its `send.` subdomain) |
| TXT/CNAME | per Resend dashboard | DKIM + SPF for `send.dnanu.de` |
| TXT | `_dmarc.dnanu.de` | `v=DMARC1; p=quarantine; rua=mailto:admin@dnanu.de` → `p=reject` after 30 clean days |
| TXT | `_mta-sts.dnanu.de` | `v=STSv1; id=20260806T000000` — MTA-STS policy lookup (RFC 8461) |
| CNAME | `mta-sts.dnanu.de` | `<tunnel-id>.cfargotunnel.com` (proxied) — serves .well-known/mta-sts.txt |
| TXT | `_smtp._tls.dnanu.de` | `v=TLSRPTv1; rua=mailto:admin@dnanu.de` — TLS-RPT reporting (RFC 8460) |
| TLSA | `_25._tcp.mail.dnanu.de` | `3 1 1 <auto-synced SPKI hash>` — DANE EE (RFC 6698), auto-updated via cloudflare-tlsa-sync |
| — | `*.nanulab.de` / `nanulab.de` | **no public A records** (VPN-only; AdGuard rewrites locally — §3.4) |
| CNAME | `dnanu.de`, `www`, `autoconfig`, `mta-sts` | `<tunnel-id>.cfargotunnel.com` (proxied) |

`autoconfig.dnanu.de/mail/config-v1.1.xml`: static XML (Thunderbird auto-setup) served by the blogs nginx vhost.

### 4.5 Hardening & monitoring notes

**DANE TLSA (D1):** `3 1 1` (DANE-EE / SPKI / SHA-256), fully automated via `cloudflare-tlsa-sync` — computes cert SPKI hash, upserts TLSA record via CF API. Triggers: ACME `postRun` (renewal), daily persistent timer, boot. Gap: TTL 120s, DANE-enforcing senders tempfail+retry. **DANE only activates once the zone's DS record is published at DENIC.**

**RBL policy (D2):** rspamd-side only. Stock free lists (mailspike, dnswl, spameatingmonkey, blocklist.de, virusfree, SURBL/URIBL/DBL) active; spamhaus explicitly disabled. No `reject_rbl_client` in postfix.

**MTA-STS (D3):** Dedicated `mta-sts.dnanu.de` vhost on nginx 127.0.0.1:8080, fronted by cloudflared tunnel. Policy: `mode: enforce, max_age: 86400`. World-readable.

**Postfix restrictions (D4):** RFC-conformance checks only — helo required, non-FQDN/invalid helo rejected, non-FQDN sender/recipient rejected, unknown sender/recipient domain rejected, unauth pipelining rejected. No callouts, no postscreen.

**Outbound TLS (D5):** Static `verify` policy for `[smtp.resend.com]:465` in `tls_policy` map (prepended before tlspol socketmap).

**Monitoring (D6):** `mail-queue-watch` timer (15 min) alerts via Resend HTTPS API to `hey@dnanu.de` if postfix/dovecot/rspamd down, queue >2, or oldest >30 min. Rate-limited (6 h cooldown). Independent of local postfix. *(Note: the systemd unit is `dovecot.service`, not `dovecot2` — watchdog fixed 2026-08-08.)*

**DMARC (D7):** `p=quarantine` now; flip to `p=reject` after 30-day clean report window.

## 5. Storage (ZFS + disko)

- `disko` targets `/dev/sda` (test) — human verifies device path at install. GPT: 1G ESP `/boot` + ZFS root pool.
- **Dell mirrors prod (2026-08-08 ruling):** the Dell is reformatted to have real `/fast` and `/slow` as separate ZFS datasets (different recordsize/compression, mimicking the future pools) so the prod switch is drop-in. Prod: pools `fast` (SSD mirror) + `slow` (HDD mirror), same mountpoints.
- **Prod switch contract:** change only `disko.nix` + `hardware-configuration.nix` + `zfsArcMax` in settings.nix. Everything else (services, network, paths) identical.
- **Mandatory:** `networking.hostId = "<8 hex>";` (generate once, keep forever) and `boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;`
- ARC cap: `boot.kernelParams = [ "zfs.zfs_arc_max=1073741824" ];` on Dell; `settings.nix` parameter.
- **Directory layout is declarative** (`modules/system/storage-layout.nix`, systemd.tmpfiles, `root:media 2775` setgid):

```
/fast/user/hey/{work/{audio,video,images,literature,documents}/{apple,windows,linux},academic,downloads}
/fast/immich            # Immich-managed, black box
/fast/mail              # Maildir
/fast/backups/postgres  # nightly dumps, restic source
/slow/shared-media/video/{shows,movies}
/slow/shared-media/audio/{music,audiobooks,podcasts}
/slow/shared-media/literature/{books}
/slow/downloads/{qbittorrent,sabnzbd,slskd}   # *arr hardlink source
```
All media services + nextcloud + immich get supplementary group `media` (set via `SupplementaryGroups` on their systemd units).

## 6. Repo Structure

```
nixos-homelab/
├── flake.nix              # inputs: nixpkgs(26.05), sops-nix, disko, vpn-confinement, simple-nixos-mailserver
├── settings.nix           # THE user file: domains, IPs, email, vpn.forwardedPort, zfsArcMax, sshPubKey, hostId
├── users.nix              # v4: single source of truth for users, devices, and IP allocation (100 explicit entries)
├── wireguard-pubkeys.nix  # GENERATED — 97 WG public keys (committed, not secret)
├── scripts/gen-wg-keys.sh # idempotent WG key management script
├── secrets/secrets.yaml   # sops-encrypted, safe to commit
├── .sops.yaml             # age public key
├── AGENTS.md              # how the agent system works
├── TODO/                  # work tracker (one folder per project area)
├── hosts/
│   ├── homelab/{configuration.nix,hardware-configuration.nix,disko.nix}
│   └── installer/         # custom ISO w/ ssh key for nixos-anywhere
└── modules/
    ├── networking/{acme,adguard,base,cloudflare,ddclient,kea,nginx,nginx-helpers,wireguard}.nix
    ├── services/{authelia,cloudflare-dns,collabora,immich,ios-profile,mail,nextcloud,vaultwarden}.nix
    ├── system/{sops,storage-layout,users,zfs}.nix
    └── mobile-profile.nix
```

## 7. Secrets Inventory (sops-nix)

`cloudflare_api_token`, `cloudflare_account_token`, `cloudflared_tunnel_cred`, `resend_api_key`, `mail_hey`, `mail_admin`, `airvpn_wg_conf`, `b2_account_id`, `b2_account_key`, `restic_password`, `nextcloud_admin_pass`, `vaultwarden_admin_token`, `slskd_env` (`SLSKD_SLSK_USERNAME/PASSWORD`), `authelia_jwt`, `authelia_storage_key`, `authelia_users_yaml` (10 users: admin + 9 regular), `mobileca_key`, `mobileca_cert`, `booklore_db_password`, `wireguard_server_private`, `wireguard_peer_<hostname>-vpn_private`, `wireguard_peer_<hostname>-vpn_psk` (97 peers × 2 = **194** WG keys).

## 8. TLS

`security.acme` DNS-01 via Cloudflare (lego): `*.nanulab.de`, `*.dnanu.de`, `mail.dnanu.de`. Cert dir owned `acme:acme`; only nginx is in the `acme` group. Postfix/Dovecot read certs during root-init before privilege drop — verified working end-to-end (live TLSv1.3 on all ports). `reloadServices` set. No HTTP-01 (port 80 closed).

## 9. Service Map — ✅ all modules verified in pinned 26.05

| Service | Module | URL (VPN only unless noted) | Status | Notes |
|---|---|---|---|---|
| Nginx | `services.nginx` | — | ✅ | reverse proxy, ACME, ACL v4 (helpers in nginx-helpers.nix) |
| AdGuard Home | `services.adguardhome` | `adguard.nanulab.de` (admin-IP-only) | ✅ | DNS-only; `mutableSettings=false`; persistent clients from users.nix |
| Kea | `services.kea.dhcp4` + `.dhcp6` | — | ✅ | LAN DHCPv4 + DHCPv6 (ULA); 10 host reservations |
| WireGuard | `networking.wireguard` | — | ✅ | §3.3, 97 peers |
| ddclient | `services.ddclient` | — | ✅ | protocol cloudflare, passwordFile=sops, 300s, use=web |
| cloudflared | `services.cloudflared` | — | ✅ | §3.6, config_src=local |
| Mail | SNM `mailserver.*` | `mail.dnanu.de` | ✅ | §4, verified green |
| Cloudflare DNS sync | `modules/services/cloudflare-dns.nix` | — | ✅ | DNS/DKIM/TLSA/MTA-STS records upsert, idempotent, alerts |
| Authelia | `services.authelia` | `profile.dnanu.de` | ✅ | 10 users, auth_request gate |
| Nextcloud | `services.nextcloud` | `cloud.nanulab.de` | ✅ | pg+redis; apps mail/calendar/contacts/**richdocuments**; 16G upload; RAM-tuned |
| Collabora Online | `services.collabora-online` | `office.nanulab.de` | ✅ | Nextcloud Office backend; `ssl.enable=false`+`ssl.termination=true` (nginx terminates) |
| Immich | `services.immich` | `photos.nanulab.de` | ✅ | `mediaLocation=/fast/immich`; ML off on Dell |
| Vaultwarden | `services.vaultwarden` | `vault.nanulab.de` | ✅ | SQLite; `SIGNUPS_ALLOWED=false`; Argon2 ADMIN_TOKEN; declared SMTP via local postfix |
| Jellyfin | `services.jellyfin` | `watch.nanulab.de` | ⬜ | **the ONLY player** — movies/TV/music/audiobooks/books. SNB iGPU: `intel-vaapi-driver`; prod: `intel-media-driver` |
| ~~Navidrome~~ | ~~`services.navidrome`~~ | — | 🗑 dropped | replaced by Jellyfin (2026-08-08) |
| ~~Audiobookshelf~~ | ~~`services.audiobookshelf`~~ | — | 🗑 dropped | podcasts dropped; audiobooks → Jellyfin library (manual) |
| ~~Booklore~~ | ~~OCI container~~ | — | 🗑 dropped | e-books served by Jellyfin book library (2026-08-08) |
| Seerr | `services.seerr` | `requests.nanulab.de` | ⬜ | requests for movies/shows (merged Plex/Jellyfin/Emby project) |
| Sonarr/Radarr/Lidarr | `services.<name>` | `*.nanulab.de` | ⬜ | TV/movies/music managers; Readarr (books) pinned + rreading-glasses mirror |
| ~~Prowlarr~~ | `services.prowlarr` | — | ⬜ | indexer manager (one for all arrs) |
| ~~Bazarr~~ | — | — | 🗑 dropped | no subtitle layer (2026-08-08) |
| qBittorrent | `services.qbittorrent` | via VPN bridge IP | ⬜ | confined; listen port = AirVPN forwarded port |
| SABnzbd | `services.sabnzbd` | via VPN bridge IP | ⬜ | confined |
| slskd | `services.slskd` | via VPN bridge IP | ~ optional | confined; music downloader (only if kept — 2026-08-08 discussion) |
| ~~beets~~ | — | — | 🗑 dropped | no tag post-processor (arrs manage, Jellyfin reads tags) |
| ~~soularr~~ | — | — | 🗑 dropped | Lidarr↔slskd bridge dropped with beets/slskd |
| Home Assistant | `services.home-assistant` | `home.nanulab.de` | ⬜ | `trusted_proxies` for nginx |
| Beszel | `services.beszel.hub` + `.agent` | `status.nanulab.de` | ⬜ | agent monitors systemd units; mail-queue alert |
| Restic | `services.restic.backups.b2` | — | ⬜ | §11 |
| VPN | `vpnNamespaces.wg` (VPN-Confinement flake input) | — | ⬜ | `wireguardConfigFile`=sops; `portMappings`; `openVPNPorts`=AirVPN forwarded port; `systemd.services.{qbittorrent,sabnzbd,slskd}.vpnConfinement` |

## 10. The `.mobileconfig` / profile generator — ✅ LOCKED design

1. Human generates a root CA on their machine (`openssl`); key+cert stored in sops (`mobileca_*`). **Never** generate in a Nix build — `/nix/store` is world-readable. *(Unsigned certs are acceptable for now — human ruling, Mac dead.)*
2. Systemd oneshot renders a static `.mobileconfig` (payloads: IMAP `mail.dnanu.de:993` SSL, SMTP `mail.dnanu.de:465` SSL, CalDAV + CardDAV → `cloud.nanulab.de/remote.php/dav`, embedded CA cert payload, **no passwords** — iOS prompts at install), signs it via `openssl smime -sign`, writes to `/var/lib/mobileprofile/`.
3. nginx serves it at `profile.dnanu.de` behind Authelia. The standalone DNS `.mobileconfig` was **retired 2026-08-06** — DNS rides in the WireGuard peer configs. The vhost also serves per-user WireGuard configs + QR PNGs: `profile.dnanu.de/<user>/` (wireguard-profile-render oneshot). Admin sees 7 QRs, users see 10.
4. Flow: VPN or LAN on → open `profile.dnanu.de` → Authelia login → download → install → Mail/Calendar/Contacts work. Service TLS is real Let's Encrypt — the CA exists only for the "Verified" badge.

## 11. Backups (Restic → Backblaze B2)

- `services.postgresqlBackup` nightly: `nextcloud`, `immich` → `/fast/backups/postgres`.
- Restic nightly, source = ZFS snapshot (crash-consistent) + dumps:
  - **Include:** `/fast` (Nextcloud files, Immich, Maildir, dumps), `/var/lib` app state for every service in §9, `/etc/nixos`.
  - **Exclude:** `/slow/shared-media`, `/slow/downloads`, caches.
- `passwordFile` + `environmentFile` (B2 creds) from sops. Prune: 7 daily / 4 weekly / 12 monthly.
- **Restore drill** (documented, tested once): new machine → `nixos-anywhere` → `restic restore` → reboot → done.

## 12. Deployment Runbook

**On the human's machine (once):** generate age keypair (private → USB + password manager); generate mobile CA; clone repo; edit `settings.nix`; `sops secrets/secrets.yaml` to fill §7; commit via PR.
**Install:** boot NixOS ISO on Dell (ethernet) → start sshd, set password → `nix run github:nix-community/nixos-anywhere -- --flake .#homelab --extra-files <dir-with-age-key> root@<ip>` → disko formats, installs, reboots.
**Day-2 flow:** PR merges to `main` → server: `cd /etc/nixos && git pull origin main && nixos-rebuild switch --flake .#homelab`. Rollback = `nixos-rebuild switch --rollback` or boot menu.
**1% manual (~45 min):** disable Speedport DHCPv4 (+DHCPv6 if UI allows); switch dumitru iPhone off manual `10.0.0.3` → DHCP (Kea reservation hands it `10.0.0.10`); verify UDP 51820 forward (done 2026-08-05); keep Speedport DHCP pointing at AdGuard + IPv6 enabled; **Speedport v6 pass-through** (fixes internet.nl IPv6 — §3.5); fill iza/kerem/hannah MACs in `users.nix`; re-scan ALL WG QRs post-deploy; distribute Authelia passwords; optional `rm /var/lib/AdGuardHome/leases.json`; revoke Tailscale OAuth client + remove machines; Nextcloud admin + link Mail app to local IMAP; Jellyfin/Navidrome/ABS/Booklore admin accounts + libraries; Prowlarr indexers; connect *arrs to downloaders; Seerr↔Jellyfin; Vaultwarden admin; HA onboarding; Beszel agent key; **mail-tester.com + internet.nl after mail deploy (done 2026-08-07 — see §4.1); flip DMARC to `p=reject` after 30 clean days; publish DS records at registrar (both zones, §3.7, activates DANE).**

## 13. Verification Suite (run after install / deploy)

`zpool status` · `wg show` (handshakes < 2 min old for active peers, peers at 10.0.10.x, 97 peers listed) · `systemctl status kea-dhcp4-server kea-dhcp6-server` · Kea leases: arch=`10.0.0.3`, dumitru iPhone=`10.0.0.10`, Xbox=`10.0.0.41`, Samsung TV=`10.0.0.21` · `dig @10.0.0.2 mail.dnanu.de` (→10.0.0.2) · `dig mail.dnanu.de @1.1.1.1` (→home IP) · `dig vpn.dnanu.de @1.1.1.1` (→home IP) · `dig @fd10::2 cloud.nanulab.de` → 10.0.0.2 · cellular with tunnel up: `dig cloud.nanulab.de` → 10.0.0.2 and `curl -I https://cloud.nanulab.de` works · `curl -kI https://profile.dnanu.de/admin/` (admin sees 7 QRs) · nginx ACL: guest IP → 403 on all vhosts · `curl -k https://profile.nanulab.de` → **404** (catch-all) · AdGuard query log shows 10.0.10.x sources labeled · `swaks --to hey@dnanu.de --server <home-ip>` from outside · send via iOS → check Resend dashboard · LAN: fresh guest lease ∈ .100-.200 · torrent IP-leak test in qBittorrent · `restic check` · lid-close test · `systemctl --failed` empty · `dig +dnssec +adflag dnanu.de @9.9.9.9` (AD bit set) · `delv dnanu.de`.

## 14. Update Policy

Quarterly: `nix flake update` → build → test → switch. Rollback via boot menu / `flake.lock` git history. No unattended upgrades.

## 15. Phase 2 Backlog (documented, NOT built)

- Nextcloud Talk (needs TURN + open ports → **Phase 2 forever**)
- MeTube / Pinchflat (YouTube downloader)
- IPTV
- Headscale + headplane UI (both native, verified 26.05 — if declarative WG peer management ever becomes a burden; needs TCP 8443 forward, preauth keys or OIDC IdP, iOS via Tailscale app's alternate-server setting)
- Multi-user mailboxes
- **Nextcloud Office powered by Euro-Office** (June 2026, ONLYOFFICE-based; not in nixpkgs — keep Collabora until it lands in a pinned channel; decision 2026-08-08)
- **Installer project** (`install.sh` on live ISO): fork repo → create GitHub repo on user's account → interactive Q&A (users/accounts/emails/aliases/apps/disks/API tokens) → generate config + sops → print manual steps. Assumes same stack (Resend/CF/INWX/WG/SNM). Build after v1. *(Note: Nextcloud/Vaultwarden accounts persist in their DBs across reboot AND rebuild — installer only creates on first install.)*
- DANE TLSA active once DS published at DENIC (§3.7)

## 16. Key References

- SNM: https://nixos-mailserver.readthedocs.io/en/latest/ (options: `accounts.<name>.{aliases,sieveScript}`, `enableSubmissionSsl`, `x509.useACMEHost`, relay workaround = services.postfix directly)
- VPN-Confinement: https://github.com/Maroka-chan/VPN-Confinement · nixarr VPN docs: https://nixarr.com/wiki/vpn/ (AirVPN = static port forward, wg-quick)
- Resend SMTP: https://resend.com/docs/send-with-smtp (`smtp.resend.com:465`, user `resend`, pass = API key)
- Readarr retirement: https://github.com/readarr/readarr (mirror: rreading-glasses)
- disko: https://github.com/nix-community/disko · nixos-anywhere: https://github.com/nix-community/nixos-anywhere · sops-nix: https://github.com/Mic92/sops-nix
- Beszel/slskd/seerr modules: nixpkgs `services.beszel.{hub,agent}`, `services.slskd`, `services.seerr` (26.05)
- Booklore: https://github.com/booklore-app/booklore · soularr: https://github.com/mrusse/soularr · Hugo: https://gohugo.io · rreading-glasses mirror for Readarr metadata
- WireGuard: https://www.wireguard.com · headscale: https://github.com/juanfont/headscale · headplane: https://github.com/tale/headplane
- Mail hardening RFCs: RFC 8460 (TLS-RPT), RFC 8461 (MTA-STS), RFC 6698 (DANE TLSA), RFC 7489 (DMARC), RFC 7208 (SPF), RFC 6376 (DKIM)
- Rspamd: https://rspamd.com · SNM rspamd integration: https://nixos-mailserver.readthedocs.io/en/latest/
- Resend API (watchdog): https://resend.com/docs/api-reference/emails/send-email
