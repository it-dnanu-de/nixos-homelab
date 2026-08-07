# TODO — 11 Monitoring & Backups

**Status:** ⬜ not started (build step 8) · **Owner:** nixos-builder · **Modules:** `modules/services/monitoring.nix`, `modules/system/backups.nix`

> **No alert emails (2026-08-08):** the Glance dashboard surfaces status. `mail-queue-watch` writes a status file Glance reads. Beszel monitors everything.

## Glance dashboard (`services.glance`) — `status.nanulab.de` (admin-only)
- [ ] Native module (26.05 ✅ verified)
- [ ] Widgets: service health (from Beszel + mail-queue status file), weather, RSS, links to all services
- [ ] Reads `/var/lib/mail-alert/status.json` (from mail-queue-watch)
- [ ] nginx admin-tier vhost

## Beszel (`services.beszel.hub` + `.agent`)
- [ ] hub + agent modules (26.05 ✅ verified)
- [ ] Monitors EVERYTHING: host (CPU/RAM/disk) + services + containers
- [ ] Agent key (1% manual pairing)

## mail-queue-watch (rework)
- [ ] Remove Resend email alerting (no self-emails)
- [ ] Write status file `/var/lib/mail-alert/status.json` for Glance instead

## Restic → Backblaze B2 (OpenCode.md §11)
- [ ] `services.restic.backups.b2` module
- [ ] `passwordFile` + `environmentFile` (B2 creds) from sops
- [ ] **Include:** `/fast` (Nextcloud files, Immich media + DB, Maildir, dumps, `/fast/containers`), `/var/lib` app state for all §9 services, `/etc/nixos`
- [ ] **Exclude:** `/slow/shared-media`, `/slow/downloads`, caches
- [ ] Source = ZFS snapshot (crash-consistent) + postgres dumps
- [ ] **Nightly 02:00; retention 7 daily / 4 weekly / 12 monthly** (2026-08-08)
- [ ] B2/R2 region decided at build
- [ ] `restic check` in verification
- [ ] Restore drill documented + tested once (§12)

## PostgreSQL backups
- [ ] `services.postgresqlBackup` nightly: nextcloud, immich → `/fast/backups/postgres` (already enabled)

## Health
- [ ] `systemctl --failed` empty in §13 suite
