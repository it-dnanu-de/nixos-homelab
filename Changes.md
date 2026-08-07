# Changes.md — temporary session log (wiped into OpenCode.md at end of session)

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
