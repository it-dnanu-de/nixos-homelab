# TODO — 06 Cloud Services (self-hosted iCloud — Nextcloud is the ENTIRE cloud)

**Status:** ~ rework (2026-08-08/12: Nextcloud becomes the whole cloud, runs as podman AIO; Immich + Vaultwarden dropped) · **Owner:** builder + architect · **Modules:** `modules/services/nextcloud.nix` (podman AIO)

> **Nextcloud = the self-hosted iCloud (2026-08-08).** One Authentik login → invite → native iOS/Android clients (mail/cal/contacts/files via IMAP/CalDAV/CardDAV/WebDAV) → iCloud-style launcher. Runs as **podman AIO** (not the nixpkgs module — 2 majors behind). Drop Immich + Vaultwarden. Memories + Passwords + EuroOffice install from the AIO app store.

## Nextcloud — podman AIO — `cloud.nanulab.de`
- [ ] `virtualisation.oci-containers.backend = "podman"`
- [ ] Nextcloud AIO container (`ghcr.io/nextcloud-releases/all-in-one:v13.4.1`, pinned) + sops env
- [ ] AIO sub-containers: postgres, redis, apache, **eurooffice** (`ghcr.io/euro-office/documentserver:v9.3.2`)
- [ ] Loopback ports → nginx ingress (user-tier ACL)
- [ ] **EuroOffice** replaces Collabora (Office)
- [ ] Apps from AIO app store: **Memories** (photos, replaces Immich), **Passwords** (replaces Vaultwarden), Notes, Talk (⚠️ TURN decision pending)
- [ ] `defaultapp = "dashboard"` (iCloud-style landing)
- [ ] **iCloud-style launcher** (app tile grid after Authentik login — user-facing only; separate from Glance admin dashboard)
- [ ] `/fast/users/<user>` as Nextcloud data dir + Memories index

## Dropped (2026-08-08/12)
- 🗑 **Immich** → replaced by Nextcloud Memories
- 🗑 **Vaultwarden** → replaced by Nextcloud Passwords
- 🗑 **Collabora** → replaced by EuroOffice (AIO)
- 🗑 mobileconfig → native iOS/Android clients connect directly (IMAP/CalDAV/CardDAV/WebDAV)

## Native client config (mobile/desktop)
- [ ] iOS: Mail (IMAP/SMTP), Calendar (CalDAV), Contacts (CardDAV), Files (WebDAV) + Nextcloud app (Memories/Passwords/Notes/Talk)
- [ ] Desktop: Nextcloud web apps (Files/Mail/Calendar/Contacts/Memories/Passwords/Notes/Talk)
- [ ] Document the exact per-platform setup on the launcher/profile page

## Shared
- [ ] nginx user-tier vhost (frontend-cloud zone .30)
- [ ] postgresqlBackup nightly → /fast/backups/postgres
- [ ] restic include `/fast` (Nextcloud files + Memories)
