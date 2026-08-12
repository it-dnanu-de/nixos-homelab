---
name: mail-stack
description: Use when working on the mail system — simple-nixos-mailserver, Postfix/Resend relay, Dovecot, Rspamd, sieve rules, mail DNS records, DNSSEC for mail.
---

# Mail Stack (OpenCode.md §4)

## Stack — LOCKED
- **simple-nixos-mailserver** (Postfix + Dovecot + Rspamd): IMAP 993, submission 465 (SMTPS) + 587, LMTP, ManageSieve.
- Nextcloud provides CalDAV/CardDAV/WebDAV + the Mail web app. Stalwart is **not** used.
- Inbound port 25 direct. Outbound via Resend relay. No VPS relay.

## Accounts
- `hey@dnanu.de` — primary, aliases `it@ health@ wealth@ creative@ academic@ accounts@ contact@ partners@`, plus per-alias sieve `fileinto :create`.
- `admin@dnanu.de` — services admin, aliases `postmaster@ hostmaster@ webmaster@ abuse@ security@`.
- **9 family mailboxes** (`dumitru@ adela@ tiberiu@ david@ ramona@ tibisor@ iza@ kerem@ hannah@`) — **derived from `users.nix`** (single source of truth, §4.2), sops `mail_<user>` per account.
- `hashedPasswordFile` points at `config.sops.secrets.mail_hey.path` / `mail_admin.path`.
- Sieve: `if address :is "to" "it@dnanu.de" { fileinto :create "IT"; stop; }` x8; fallthrough -> INBOX (only `hey@` lands there).

## Pinned-SNM gotchas (verified 2026-08 against SNM master)
- `loginAccounts` was **renamed to `accounts`** — `mkRenamedOptionModule` migrates it, but write `accounts` in new config.
- `certificateScheme` was **removed**. Use `mailserver.x509.{useACMEHost, certificateFile, privateKeyFile}` instead (manual certs = `x509.certificateFile` + `x509.privateKeyFile` pointing at `security.acme` outputs).
- `sieveScript` per account and global `recipientDelimiter` exist (sub-addressing `hey+foo@` works).
- Always re-verify against the **pinned SNM flake input** before writing — master moves.

## Outbound relay (Resend) — LOCKED
SNM has no relay option; use Postfix directly:
- `relayhost = [smtp.resend.com]:465`, user `resend`, password = API key.
- `mapFiles."sasl_passwd"` from a sops template (mode 0600): `[smtp.resend.com]:465 resend:<API key>`.
- `smtp_tls_wrappermode = yes`, `smtp_sasl_auth_enable = yes`, `smtp_sasl_security_options = noanonymous`.
- Static `tls_policy` map with `[smtp.resend.com]:465 verify` (prepended before the tlspol socketmap) — CA+hostname-verified TLS on the money path. Do NOT set `smtp_tls_security_level = encrypt` globally (tlspol + tls_policy handle it).

## DNS records (Cloudflare, grey cloud unless noted)
| Type | Name | Value |
|------|------|-------|
| A | mail.dnanu.de | dynamic home IP (ddclient), **must stay unproxied or SMTP dies** |
| AAAA | mail.dnanu.de | home IPv6 GUA (ddclient, ipify-ipv6) |
| MX | dnanu.de, nanulab.de | mail.dnanu.de prio 10 |
| TXT | dnanu.de | SPF `v=spf1 -all` (nothing sends with envelope @dnanu.de; Resend uses `send.` subdomain) |
| TXT/CNAME | per Resend dashboard | DKIM + SPF for send.dnanu.de |
| TXT | _dmarc.dnanu.de | `v=DMARC1; p=quarantine; rua=mailto:admin@dnanu.de` -> `p=reject` after 30 clean days |
| TXT | _mta-sts.dnanu.de | `v=STSv1; id=...` (MTA-STS policy) |
| TXT | _smtp._tls.dnanu.de | `v=TLSRPTv1; rua=mailto:admin@dnanu.de` |
| TLSA | _25._tcp.mail.dnanu.de | `3 1 1 <SPKI>` — auto-synced via cloudflare-tlsa-sync |
| CNAME | mta-sts.dnanu.de | `<tunnel-id>.cfargotunnel.com` (proxied) |
| DNSSEC | dnanu.de, nanulab.de | enabled at Cloudflare, DS published at DENIC — activates DANE |

## Gotchas
- Telekom inbound-25 flakiness is accepted; health-check via Beszel mail-queue alert.
- Readarr-style retirement risk: none here; SNM is maintained. Verify `sieveScript` option exists in the pinned SNM release before using.
