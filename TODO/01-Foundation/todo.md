# TODO — 01 Foundation (flake, settings, users, secrets)

**Status:** ✅ done and deployed (gen 72) · **Owner:** builder · **File refs:** `flake.nix`, `settings.nix`, `users.nix`, `modules/system/sops.nix`, `secrets/secrets.yaml`, `.sops.yaml`, `scripts/gen-wg-keys.sh`, `wireguard-pubkeys.nix`

## Flake
- [x] `flake.nix` pins nixpkgs `nixos-26.05` + sops-nix + disko + vpn-confinement + simple-nixos-mailserver
- [x] `nixosConfigurations.homelab` with `specialArgs` (settings, users)
- [x] All inputs follow nixpkgs where applicable

## Settings (`settings.nix`)
- [x] domains (public, internal, mail), hostname, hostId
- [x] IPs (10.0.0.2/16 host, ULA fd10::2/64), gateway, container zones (§3.1), WG server 10.0.80.2
- [x] cloudflare.tunnelId → `734c3fa5` (local-config tunnel, 2026-08-07)
- [x] timeZone
- [ ] `sshPubKey` placeholder — **human must set real key**
- [ ] `zfsArcMax` parameterised (Dell cap 1GB; prod different)

## Users (`users.nix`)
- [x] v4 addressing: 100 explicit device entries, blocks per user (admin 0-9, dumitru .10-19, …)
- [x] Helpers: `isPeer`, `wgPeers` (97), `wgPeerNames`, `dhcpReservations`, `userToIps`
- [ ] MACs for iza / kerem / hannah still `TODO`
- [ ] Sanity: base + [user]1-9 naming, no duplicates (ran in build — keep test)

## Secrets (sops)
- [x] `.sops.yaml` age public key
- [x] `secrets/secrets.yaml` encrypted, public-safe
- [x] Registered in `modules/system/sops.nix`
- [x] `cloudflare_account_token` added 2026-08-07 (tunnel ops)
- [ ] Fill remaining `REPLACE_ME`: `airvpn_wg_conf` (after AirVPN subscription), `restic_password` (B2 backup build). `nextcloud_admin_pass` + `vaultwarden_admin_token` are set. `slskd_env` kept (slskd optional). `booklore_db_password` removed 2026-08-08.

## WireGuard keygen (`scripts/gen-wg-keys.sh`)
- [x] Idempotent two-pass v3→v4 rename
- [x] 97 peer keypairs + 194 sops keys
- [x] `wireguard-pubkeys.nix` committed (public keys only)

## Rules
- Repo public-safe: never commit Memory.md/TODO.md/plaintext secrets (`.gitignore` enforces)
- Commit after every change; PRs welcome
