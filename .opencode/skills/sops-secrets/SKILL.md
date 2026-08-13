---
name: sops-secrets
description: Use whenever a secret is needed — API tokens, mail hashes, wifi keys, OAuth creds, admin passwords. Enforces sops-nix + age, the public-safe repo rule, and the secrets inventory.
---

# sops-nix Secrets Management

## Model (OpenCode.md §7)
- Secrets live in `secrets/secrets.yaml`, sops-encrypted, safe to commit to the public repo.
- Private age key lives on a USB drive + password manager. **Never** in the repo, never in `/nix/store` (world-readable).
- `.sops.yaml` at repo root maps files to the age public key.

## Secrets inventory (OpenCode.md §7)
`cloudflare_api_token`, `cloudflare_account_token`, `cloudflared_tunnel_cred`, `resend_api_key`, `mail_hey`, `mail_admin`, `mail_<user>` (9 family), `airvpn_wg_conf`, `b2_account_id`, `b2_account_key`, `restic_password`, `nextcloud_admin_pass`, `nextcloud_aio_env`, `slskd_env` (`SLSKD_SLSK_USERNAME/PASSWORD`), `authentik_secret_key`, `authentik_postgres_password`, `user_<name>_pass_<service>` (per-user per-service password hashes), `wireguard_server_private`, `wireguard_peer_<hostname>-vpn_{private,psk}` (194 WG keys). *(authelia_*, mobileca_*, vaultwarden_admin_token removed — Authelia/mobileconfig/Vaultwarden dropped 2026-08-08.)*

## Workflow
1. Edit: `sops secrets/secrets.yaml` (age key needed; use the `secrets` command).
2. Reference from Nix via `config.sops.secrets.<name>.path`.
3. Services consume secrets via `passwordFile`, `environmentFile`, or sops templates — never inline values in modules.
4. Postfix relay password uses a sops *template* rendered mode-0440/0600 to the postfix path.

## Guardrails
- Never commit a decrypted value. If you're about to, stop.
- New secret added -> update the inventory in OpenCode.md §7.
- sops `--set` writes a YAML mapping for nested values; when a secret must be a JSON *string* (e.g. `cloudflared_tunnel_cred`), set it as a JSON-encoded string or cloudflared won't parse it.
- Authentik secrets (`authentik_secret_key`, `authentik_postgres_password`) are referenced via `environmentFile` in the authentik-nix module.
