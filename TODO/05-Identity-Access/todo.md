# TODO — 05 Identity & Access (Authentik)

**Status:** ⬜ rework (2026-08-08: Authelia → Authentik) · **Owner:** builder + architect · **Modules:** `modules/services/authentik.nix` (flake), `modules/networking/nginx-helpers.nix`

> **Authentik replaces Authelia** (2026-08-08 ruling): IdP + self-service signup/invites + admin UI + OIDC SSO. Runs via `nix-community/authentik-nix` flake (no `services.authentik` in pinned 26.05). Heavier RAM — accepted for the Dell, solved by prod 64GB.

## Authentik (`authentik.nix` — flake `nix-community/authentik-nix`)
- [ ] Add flake input `authentik-nix` (pinned, follows nixpkgs)
- [ ] `services.authentik.enable` (via the flake module) + Postgres/Redis (shared DB containers, zone `.20`)
- [ ] `environmentFile` from sops (secret key, postgres password)
- [ ] **users.nix drives it via blueprints** (YAML: users, groups, flows, providers) — new user → blueprint → account + provisioning
- [ ] **Self-service signup + one-time invites** (admin generates, role/tier baked in)
- [ ] **Admin webUI** for users/groups/roles/service access
- [ ] **OIDC SSO** into: Nextcloud, Vaultwarden, HA, Jellyfin, Glance, arrs (one login everywhere)
- [ ] Password reset + recovery emails (via local postfix → Resend)
- [ ] `auth.dnanu.de` (IdP UI) + guards `profile.dnanu.de`

## Profile / WG-QR page (inside Authentik)
- [ ] Custom Authentik page at `profile.dnanu.de`: WG QRs (wireguard-profile-render) + config downloads + setup guide (iOS/Android/PC)
- [ ] Admin sees 7 admin QRs; users see their 10
- [ ] `.mobileconfig` **dropped** (2026-08-08 — Nextcloud app for mail/cal on both platforms)
- [ ] Re-scan all WG QRs post-v5 rename

## nginx ACLs (users.nix-driven)
- [x] Admin vhosts (LAN .70.1-9 + VPN .80.3-9)
- [x] User vhosts (LAN .70.10-99 + VPN .80.3-99)
- [x] Guests (.90): nothing (403)
- [x] Catch-all 404

## WireGuard peers
- [x] 97 peers pre-provisioned, keys in sops, pubkeys in wireguard-pubkeys.nix
- [ ] v5 renumber → .80.x, re-render QRs
- [ ] Spare slots claimed = fill MAC + rebuild
