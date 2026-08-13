# TODO — 03 Networking

**Status:** ✅ done (deployed) · **Owner:** network modules · **File refs:** `modules/networking/*`

## Base (`base.nix`)
- [x] Static IP `10.0.0.2/16`, gw `10.0.0.1`, ULA `fd10::2/64` (host = bare core)
- [x] `net.ipv6.conf.all.forwarding = false` (SLAAC GUA works)
- [ ] **Router LAN → /16** (1% manual, Speedport) so all container zones are reachable
- [ ] **Zone isolation:** nftables default-deny between 10.0.x.x zones; explicit allows (frontends→backend, backends→DB, HA→IoT, nginx→all)
- [x] logind lid-switch ignore (Dell UPS)

## DNS — AdGuard (`adguard.nix`, system container .10)
- [x] DNS-only (DHCP retired to Kea), `mutableSettings = false`
- [x] Rewrites: `*.nanulab.de` → nginx (or per-service container IPs), `mail.dnanu.de` → mail container
- [x] Binds 0.0.0.0 + `::`
- [x] Persistent clients from users.nix (device labels)

## DHCP — Kea (`kea.nix`, system container .10)
- [x] dhcp4: guest pool `.90.100-.200`, host reservations (real MACs)
- [x] dhcp6: stateful ULA pool `fd10::100-200`, DNS `fd10::2`
- [ ] iza/kerem/hannah reservations (MACs TODO in users.nix)
- [ ] Users → 10.0.70.x reservations; TV/Air/Xbox → IoT (.60)

## WireGuard (`wireguard.nix` — host, users-VPN zone .80)
- [x] Server `10.0.80.2/24` (v5), endpoint `vpn.dnanu.de:51820`
- [x] **97 peers pre-provisioned** (7 admin + 90 user), split-tunnel, DNS 10.0.10.2 (AdGuard)
- [ ] **Server-routed P2P (2026-08-08):** client AllowedIPs → `10.0.0.0/16`, wg0 forwarding on. Peers reach each other + all zones via host.
- [ ] **WG v5 renumber:** all 97 peers 10.0.10.x → 10.0.80.x, re-render ALL QRs
- [ ] Spare slots: fill MACs in users.nix + rebuild

## ddclient (`ddclient.nix`)
- [x] protocol cloudflare, passwordFile from sops, interval 300s, `use=web`
- [x] Publishes A + AAAA (GUA via ipify-ipv6) for mail + vpn

## ACME TLS (`acme.nix`)
- [x] DNS-01 via Cloudflare (lego), wildcard `*.nanulab.de` + `*.dnanu.de` + `mail.dnanu.de`
- [x] Cert group `acme:acme`, nginx in acme group
- [x] TLSA postRun hook (cloudflare-tlsa-sync)

## nginx (`nginx.nix`)
- [x] Reverse proxy on 127.0.0.1:8080 (+ profile on 127.0.0.1:443)
- [x] ACL v4: admin-tier + user-tier allowlists derived from users.nix
- [x] Catch-all `_` → 404 (dead-name fix)
- [ ] Service vhosts land with each service (steps 5-7)

## Cloudflare tunnel (`cloudflare.nix`) — ✅ LOCAL CONFIG (2026-08-07)
- [x] `config_src=local`, tunnel `734c3fa5`, credentials from sops
- [x] Ingress: dnanu.de/www/autoconfig/mta-sts → 8080, profile → https://localhost:443 (noTLSVerify)
- [x] Cloudflare DNS sync recreates CNAMEs to tunnel
- [x] **Rule: never touch tunnel in CF dashboard** (flips to remote-managed, kills all hostnames — recovery documented in OpenCode.md §3.6)

## DNSSEC (Cloudflare-managed)
- [x] Enabled both zones (dnanu.de + nanulab.de)
- [ ] Publish DS records at DENIC registrar (§3.7) — activates DANE
- [ ] Verify `dig +dnssec +adflag dnanu.de @9.9.9.9`

## IPv6
- [x] GUA via SLAAC, ULA fd10::/64, no v6 forwarding
- [x] Inbound :25 v6 allowed (inet family)
- [x] AAAA published for mail.dnanu.de (`2003:c8:...`, via ddclient) — resolves publicly (`tests/ip6.nl/`)
- [~] **Speedport v6 pass-through (1% manual, §3.5)** — GUA published but **v6 connections time out** (internet.nl IPv6 web reachability fails; dane.sys4.de shows v6 timeout). AAAA records OK; inbound/outbound v6 traffic through the Speedport needs the manual router step.
