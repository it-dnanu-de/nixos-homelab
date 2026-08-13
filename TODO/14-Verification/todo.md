# TODO — 14 Verification

**Status:** ~ partial (run per deploy; §13 suite) · **Owner:** deployer + joat · **Files:** `tests/` (results snapshots)

## Checklist (OpenCode.md §13)
- [x] `dig @10.0.0.2 mail.dnanu.de` → 10.0.0.2
- [x] `dig mail.dnanu.de @1.1.1.1` → home IP
- [x] `dig vpn.dnanu.de @1.1.1.1` → home IP
- [x] `dig @fd10::2 cloud.nanulab.de` → 10.0.0.2
- [x] All 5 tunnel hostnames public (200/302) — verified 2026-08-07
- [x] nginx ACL: guest → 403; catch-all → 404
- [x] Kea leases: arch 10.0.0.3, iPhone 10.0.0.10, Xbox 10.0.0.41, Samsung 10.0.0.21
- [x] AdGuard query log labels 10.0.80.x sources (users VPN)
- [x] `wg show` handshakes
- [x] DNSSEC: `dig +dnssec +adflag dnanu.de @9.9.9.9`, `delv`
- [x] test snapshots in `tests/` (internet.nl, dnsviz, zonemaster, mail-tester, etc.)

## Pending
- [ ] `zpool status` + ARC within cap
- [ ] cellular + tunnel: `dig cloud.nanulab.de` + `curl -I https://cloud.nanulab.de`
- [ ] `curl -k https://profile.nanulab.de` → 404 (dead name)
- [ ] inbound SMTP from outside — covered by mail-tester 2026-08-07 ✅ (see 04-Mail); re-run `swaks` after IPv6 pass-through
- [ ] send via iOS → Resend dashboard
- [ ] guest lease ∈ .100-.200
- [ ] torrent IP-leak test (qBittorrent)
- [ ] `restic check`
- [ ] lid-close test
- [ ] `systemctl --failed` empty
- [ ] internet.nl IPv6 subtest (blocked on Speedport v6 pass-through — 03-Networking)
- [ ] full suite after each milestone deploy

## Gate
- Run §13 after every `nixos-rebuild switch` of a milestone.
