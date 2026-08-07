# TODO — 13 Deployment

**Status:** ~ partial · **Owner:** deployer · **File refs:** `hosts/homelab/`, `hosts/installer/`, skills/deployment

## Installer ISO (`hosts/installer/`)
- [ ] Custom ISO with ssh key for nixos-anywhere (currently just `.gitkeep`)
- [ ] SSH password auth enabled on ISO (per human ruling)

## First install (nixos-anywhere)
- [x] Runbook documented (§12): boot ISO → sshd → `nix run ... -- --flake .#homelab --extra-files <age-key-dir> root@<ip>`
- [ ] Actual fresh install tested (current box deployed via earlier flow)
- [ ] Disko formats `/dev/sda` (human verifies device path at install)

## Day-2 rebuild flow
- [x] `/etc/nixos` git clone on server, `git pull && nixos-rebuild switch --flake .#homelab`
- [x] Commit → push → pull → switch → verify (this session: gen 71 → 72)
- [x] `nix flake check` pre-flight

## 1% manual checklist (§12) — mostly pending
- [ ] Disable Speedport DHCPv4 (+DHCPv6 if UI allows); point DNS at AdGuard; keep IPv6
- [ ] Switch dumitru iPhone off manual 10.0.0.3 → DHCP
- [ ] Verify UDP 51820 forward (done 2026-08-05 ✅)
- [ ] Fill iza/kerem/hannah MACs
- [ ] Re-scan ALL WG QRs post-deploy
- [ ] Distribute Authelia passwords (10 users)
- [ ] Optional: `rm /var/lib/AdGuardHome/leases.json`
- [ ] Revoke Tailscale OAuth + remove machines (Tailscale console)
- [ ] Nextcloud admin + Mail app → local IMAP
- [ ] Jellyfin admin + libraries
- [ ] Prowlarr indexers; connect *arrs to downloaders
- [ ] Seerr ↔ Jellyfin; Vaultwarden admin; HA onboarding; Beszel agent key
- [x] mail-tester.com + internet.nl — **run 2026-08-07** (mail-tester 0.1 SPF/DKIM/DMARC pass; MECSA 100s; internet.nl dnanu 90%, mail 61% — only IPv6 fail). Flip DMARC reject after 30 clean days.
- [ ] Speedport v6 pass-through (fixes internet.nl IPv6 subtest) — see 03-Networking
- [ ] Publish DS records at DENIC (both zones) — activates DANE (TLSA already published + matching)
