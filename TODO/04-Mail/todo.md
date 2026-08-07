# TODO — 04 Mail

**Status:** ✅ done (deployed, audited) · **Owner:** mail-stack skill · **File refs:** `modules/services/mail.nix`, `modules/services/cloudflare-dns.nix`

## Stack (simple-nixos-mailserver)
- [x] SNM: Postfix + Dovecot + Rspamd, fqdn `mail.dnanu.de`
- [x] IMAP 993, submission 465 (SMTPS) + 587, ManageSieve, LMTP
- [x] `openFirewall=false` (ports scoped by host firewall, audit F1)

## Accounts (OpenCode.md §4.2)
- [x] `hey@dnanu.de`: 8 aliases (it/health/wealth/creative/academic/accounts/contact/partners) + sieve fileinto rules
- [x] `admin@dnanu.de`: postmaster/hostmaster/webmaster/abuse/security aliases
- [ ] **9 family mailboxes** (`dumitru@ adela@ tiberiu@ david@ ramona@ tibisor@ iza@ kerem@ hannah@`) — derive from users.nix (2026-08-08), sops `mail_<user>` per account
- [x] `recipientDelimiter` sub-addressing (`hey+foo@`)
- [x] hashedPasswordFile from sops

## Outbound relay (Resend)
- [x] Postfix `smtp.resend.com:465` SMTPS, user `resend`, pass = API key (sops)
- [x] Static tls_policy `verify` (CA+hostname verified) — beats tlspol socketmap
- [x] `smtp_tls_wrappermode = yes`

## DNS records (Cloudflare, declarative sync)
- [x] MX both zones → mail.dnanu.de prio 10
- [x] SPF `v=spf1 -all` (nothing sends as @dnanu.de)
- [x] Resend DKIM/SPF for `send.dnanu.de` (per dashboard)
- [x] DMARC `p=quarantine` (rua admin@) → [ ] flip to `p=reject` after 30 clean days
- [x] MTA-STS TXT + mta-sts.dnanu.de CNAME + policy host (mode enforce, max_age 86400)
- [x] TLS-RPT TXT (`_smtp._tls`)
- [x] DANE TLSA `3 1 1` auto-synced from ACME cert (daily + renewal + boot)
- [ ] DANE activates once DS published at DENIC (OpenCode.md §3.7)

## Hardening (audit)
- [x] postfix RFC-conformance checks (helo/non-FQDN/unknown domain/unauth pipelining)
- [x] rspamd reject=12, stock RBLs, spamhaus disabled
- [x] TLS-RPT + DMARC reporting enabled
- [x] MTA-STS enforce mode

## Monitoring (D6)
- [x] `mail-queue-watch` timer (15 min): postfix/dovecot/rspamd down, queue >2, oldest >30 min
- [ ] **Dashboard-only (2026-08-08):** remove Resend email part → write status file → Glance reads it. No alert emails.
- [x] 6h cooldown, independent of local postfix
- [x] TLSA-sync failure alert (OnFailure → Resend)

## Verification (results captured 2026-08-07 in `tests/`)
- [x] `swaks --to hey@dnanu.de --server <home-ip>` — delivered (mail-tester 2026-08-07)
- [x] mail-tester.com: **SPF pass, DKIM valid, DMARC pass (p=quarantine), SpamAssassin 0.1** — `tests/mail-tester/mail-tester.txt`
- [x] MECSA: TLS 100 / X509 100 / DKIM 100 / DMARC 100 / DANE 100 / DNSSEC 100 / MTA-STS 100 (SPF 50 = expected, dnanu.de sends nothing; Resend uses send.dnanu.de) — `tests/mecsa/`
- [x] haveDANE: all 3 delivery tests pass (outbound DANE support) — `tests/haveDANE/`
- [x] dane.sys4.de: TLSA `3 1 1` published + matching on **both** zones — `tests/dane/`
- [x] zonemaster: only same-AS(Cloudflare 13335) warnings, no errors — `tests/zonemaster/`
- [x] dnsviz: DNSSEC chain **Secure**, VALID on both zones — `tests/dnsviz/`
- [x] internet.nl @dnanu.de: **90%** (only IPv6 fail); mail.dnanu.de: **61%** — TLS 1.3 good, **IPv6 web reachability fails** (v6 conns time out) — `tests/internet.nl/`
- [ ] iOS send via Resend dashboard (manual on device)
- [ ] internet.nl IPv6 fail → Speedport v6 pass-through (1% manual, §3.5 / 03-Networking)
- [x] `dig mail.dnanu.de @1.1.1.1` → home IP (91.50.54.159)
