# TODO — 05 Identity & Access (ZITADEL)

**Status:** ~ pass 1 landed (2026-08-13: Authentik → ZITADEL) · **Owner:** builder + architect · **Modules:** `modules/services/zitadel.nix`, `oauth2-proxy.nix`, `profile-page.nix`

> **ZITADEL replaces Authentik** (2026-08-13 ruling): native `services.zitadel` in pinned `nixos-26.05` (2.71.7). No flake input. Host-side for now; `.10` when containers land. Invite-only. One ExternalDomain: `auth.dnanu.de`.

## ZITADEL (`zitadel.nix` — native 26.05)
- [x] `services.zitadel.enable` + `tlsMode = "external"` + `openFirewall = false`
- [x] Shared host PostgreSQL (`ensureDatabases`/`ensureUsers` + password oneshot) — no new DB instance
- [x] `masterKeyFile` + `extraSettingsPaths` from sops (zitadel-owned)
- [x] `ExternalDomain = auth.dnanu.de` (singular) + `auth.nanulab.de` 301 alias
- [x] Invite-only (`LoginPolicy.AllowRegister = false`)
- [x] Transactional SMTP via local postfix → Resend, From `app@dnanu.de`
- [ ] **Pass 2 / 1% manual:** first login as `admin` → rotate bootstrap password
- [ ] **Pass 2 / 1% manual:** create Project `nanulab` → Application `profile-page` (Web, Basic, Auth Code + PKCE); copy client ID + secret
- [ ] **Pass 2 / 1% manual:** create the 9 family users → init-code email → user sets password
- [ ] OIDC SSO into Nextcloud / HA / Jellyfin / Glance / arrs — **one client per service, when that service is built** (F17)
- [ ] Containerize into `.10` (needs the container milestone — F16)
- [ ] Declarative user provisioning via Management API (no blueprint equivalent — research)

## Profile / WG-QR page (nginx + oauth2-proxy)
- [x] `oauth2-proxy.nix`: provider=`oidc`, issuer `https://auth.dnanu.de`, auth_request mode
- [x] `profile-page.nix`: static per-user dir, identity from `X-Auth-Request-Preferred-Username`
- [x] Admin sees every user's QRs; users see only their own; traversal blocked
- [x] Setup guide (iOS/Android/PC) in generated `index.html`
- [x] `.mobileconfig` **dropped** (2026-08-08)
- [x] `ios-profile.nix` deleted
- [ ] Fill `clientID` + `zitadel_oidc_client_secret` after the OIDC app exists
- [ ] Re-scan all WG QRs post-v5 rename

## nginx ACLs (users.nix-driven)
- [x] Admin vhosts (LAN .70.1-9 + VPN .80.3-9)
- [x] User vhosts (LAN .70.10-99 + VPN .80.3-99)
- [x] Guests (.90): nothing (403)
- [x] Catch-all 404

## WireGuard peers
- [x] 97 peers pre-provisioned, keys in sops, pubkeys in wireguard-pubkeys.nix
- [x] Render dirs keyed by `idpUsername` (dumitru→dumitru.nanu, iza→izabela.dwilewicz)
- [ ] v5 renumber → .80.x, re-render QRs (separate milestone)
- [ ] Spare slots claimed = fill MAC + rebuild

## Still open (not this milestone)
- [ ] `first.last` **mail** rename (email stays short-name mailbox here)
- [ ] Making `auth.nanulab.de` a second issuer (impossible — F7/D1)
