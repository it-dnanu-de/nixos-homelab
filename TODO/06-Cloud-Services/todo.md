# TODO — 06 Cloud Services

**Status:** ✅ done (deployed gen 78, declarative fixes gen 81) · **Owner:** nixos-builder · **Modules:** `modules/services/{nextcloud,collabora,immich,vaultwarden}.nix`, `nginx-helpers.nix`

> Build step 5 in OpenCode.md §12. All options/packages verified in pinned 26.05. RAM-heavy four on the Dell: Immich, Nextcloud+Collabora, Jellyfin.

## Nextcloud (`services.nextcloud`) — `cloud.nanulab.de`
- [x] Module + PostgreSQL + Redis auto-provisioned
- [x] `extraApps`: mail, calendar, contacts, **richdocuments** (Nextcloud Office)
- [x] `adminpassFile` from sops
- [x] `maxUploadSize = "16G"` + PHP-FPM RAM-tuned (`pm=ondemand, max_children=8`)
- [x] nginx user-tier vhost + ACL (merged on module's auto-vhost)
- [x] CalDAV/CardDAV/WebDAV endpoints (for mobile profile)
- [x] `postgresqlBackup` nightly → `/fast/backups/postgres`
- [x] Declarative warning fixes: maintenance window 02:30, phone region DE, serverId, log_type=file, opcache buffer 32, default_language=en, default_locale=en_US
- [ ] `defaultapp = "dashboard"` (change from `files`, 2026-08-08 ruling)
- [x] **Nextcloud Office → Collabora** wired: richdocuments 10.3.0 + wopi_url=`https://office.nanulab.de` (occ oneshot, activate-config clean)
- [ ] Nextcloud Mail app linked to local IMAP (1% manual: login → link `mail.dnanu.de:993` as hey@)
- [ ] **Declarative account creation** — human requested (not built; solution design pending)
- [ ] 2FA: skipped by human ruling (VPN-only); can add TOTP app later

## Collabora Online (`services.collabora-online`) — `office.nanulab.de`
- [x] Native module, port 9980, `ssl.enable=false` + `ssl.termination=true` (nginx terminates)
- [x] WOPI allowlist scoped to `cloud.nanulab.de`
- [x] Discovery endpoint verified (200, 39,938-byte XML)
- [x] Nextcloud Office connected (richdocuments wopi_url)

## Immich (`services.immich`) — `photos.nanulab.de`
- [x] `mediaLocation = /fast/immich`, ML **disabled** (Dell CPU)
- [x] PostgreSQL (pgvector+vchord) + Redis auto-provisioned, nightly dump
- [x] `client_max_body_size 500M`
- [ ] Admin account creation (1% manual web UI)

## Vaultwarden (`services.vaultwarden`) — `vault.nanulab.de`
- [x] SQLite, `SIGNUPS_ALLOWED=false`, WebSocket endpoints
- [x] `ADMIN_TOKEN` = **Argon2id PHC** in sops (fixes plaintext warning)
- [x] Admin-page settings declared as env config: SMTP via local postfix :25 (loopback relay → Resend), `ENABLE_PUSH_NOTIFICATION=false`, DOMAIN
- [x] nginx vhost + user ACL
- [ ] Admin portal login + any final tweaks (1% manual)

## Shared
- [x] nginx-helpers.nix refactor (ACL + mkVhost shared)
- [x] All 4 vhosts live + verified
- [ ] Add all to restic include (`/var/lib` state) — step 8
- [ ] `media` group for services that touch /fast (with §5 file-structure approval)
- [ ] Declarative file structure §5 — **printed, awaiting human approval**
