# TODO — 06 Cloud Services (self-hosted iCloud — Nextcloud is the ENTIRE cloud)

**Status:** ~ rework (2026-08-08: Nextcloud becomes the whole cloud; Immich + Vaultwarden dropped) · **Owner:** builder + architect · **Modules:** `modules/services/nextcloud.nix` (+ fetchNextcloudApp packaging)

> **Nextcloud = the self-hosted iCloud (2026-08-08).** One Authentik login → invite → native iOS/Android clients (mail/cal/contacts/files via IMAP/CalDAV/CardDAV/WebDAV) → iCloud-style launcher. Drop Immich + Vaultwarden. Package Memories + Passwords via `fetchNextcloudApp`.

## Nextcloud (`services.nextcloud`) — `cloud.nanulab.de`
- [x] Module + PostgreSQL + Redis auto-provisioned
- [x] Declarative warning fixes (maintenance window, phone region, serverId, log_type, opcache, language/locale)
- [x] RAM-tuned PHP-FPM (pm=ondemand, max_children=8)
- [x] richdocuments (Office) + WOPI → office.nanulab.de
- [x] maxUploadSize 16G
- [ ] `defaultapp = "dashboard"` (iCloud-style landing, 2026-08-08)
- [ ] **iCloud-style launcher** (app tile grid after login — user-facing only; separate from Glance admin dashboard)

## Apps to install (the iCloud surface)
- [x] Mail, Calendar, Contacts, richdocuments (already)
- [ ] **Memories** (photos) — ⚠️ package via `fetchNextcloudApp` v8.1.0 (github.com/pulsejet/memories). **Replaces Immich.**
- [ ] **Passwords** — ⚠️ package via `fetchNextcloudApp` (git.mdns.eu nightly). **Replaces Vaultwarden.**
- [ ] **Notes** — ✅ packaged (`notes`)
- [ ] **Talk** — ✅ packaged (`spreed`) — **REVISIT (2026-08-08)**: calls need TURN server + ports (3478/5349) = zero-port conflict. Decision pending: text-only vs full.
- [ ] Tasks, Bookmarks, News (RSS), Cookbook — family apps (all packaged)
- [ ] Verify `fetchNextcloudApp` packaging works for Memories/Passwords (one expr each)

## Dropped (2026-08-08)
- 🗑 **Immich** → replaced by Nextcloud Memories
- 🗑 **Vaultwarden** → replaced by Nextcloud Passwords
- 🗑 mobileconfig → native iOS/Android clients connect directly (IMAP/CalDAV/CardDAV/WebDAV)

## Native client config (mobile/desktop)
- [ ] iOS: Mail (IMAP/SMTP), Calendar (CalDAV), Contacts (CardDAV), Files (WebDAV) + Nextcloud app (Memories/Passwords/Notes/Talk)
- [ ] Desktop: Nextcloud web apps (Files/Mail/Calendar/Contacts/Memories/Passwords/Notes/Talk)
- [ ] Document the exact per-platform setup on the launcher/profile page

## Shared
- [ ] nginx user-tier vhost (frontend-cloud zone .30)
- [ ] postgresqlBackup nightly → /fast/backups/postgres
- [ ] restic include `/fast` (Nextcloud files + Memories)
