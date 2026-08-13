---
name: security-hardening
description: Use when configuring or auditing security — DNSSEC, TLS/ACME, firewall/ports, SSH policy, mail anti-abuse, or anything touching exposure to the internet.
---

# Security Hardening

## Zero-exposure model (OpenCode.md §3.2) — LOCKED
| Flow | Path | Ports open on router |
|------|------|----------------------|
| Inbound SMTP | Internet -> mail.dnanu.de -> router fwd -> 10.0.10.11:25 (mail container) | **25/tcp** |
| Public blogs + autoconfig | Cloudflare edge -> cloudflared tunnel -> nginx :8080 | none |
| Remote access | Internet -> vpn.dnanu.de -> router fwd UDP 51820 -> WireGuard | **51820/udp** |
| Everything else | Device -> WireGuard -> 10.0.80.x -> nginx ingress (10.0.10.5) | none |
| Outbound mail | Postfix -> smtp.resend.com:465 | none |
| Downloads | confined netns -> AirVPN WireGuard | none |

Host firewall (audit Finding 1): only 25/tcp + 51820/udp globally open; 53/80/443/465/587/993 source-scoped to LAN/ULA/link-local. **Zone isolation:** nftables default-deny between the 9 zones (10.0.10/.20/.30/.40/.50/.60/.70/.80/.90) — frontend→backend, backend→DB, HA→IoT, nginx→all; backends host-side (no LAN IP).
- If you open a port that isn't in this table, stop and ask. The whole network architecture depends on it.

## TLS (OpenCode.md §8)
- `security.acme` DNS-01 via Cloudflare/lego for `*.nanulab.de`, `*.dnanu.de`, `mail.dnanu.de`.
- Cert group readable by nginx, dovecot, postfix; `reloadServices` set. No HTTP-01 (port 80 closed).

## DNSSEC (OpenCode.md §3.7)
- Enabled on both Cloudflare zones (`dnanu.de`, `nanulab.de`); DS records published at DENIC (1% manual).
- Verify: `dig +dnssec +adflag dnanu.de @9.9.9.9` (AD bit), `delv dnanu.de`.
- Keep mail SPF/DKIM/DMARC correct while DNSSEC is on — a mismatched chain breaks delivery.
- `mail.dnanu.de` must stay grey-cloud/unproxied or SMTP breaks.

## SSH
- Password auth is **intentionally allowed** on the homelab. Never disable it.
- Keys are fine in addition; don't remove password support.

## Mail anti-abuse (OpenCode.md §4.5)
- postfix RFC-conformance restrictions; rspamd reject=12; MTA-STS enforce; TLS-RPT + DMARC reporting; DANE TLSA `3 1 1` auto-synced.
