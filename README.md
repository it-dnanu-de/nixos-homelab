# nixos-homelab — nanulab homelab

A 20-year NixOS homelab for **dnanu.de**. Single node, single user, 99% declarative, pinned to the `nixos-26.05` stable channel. Personal first; structured to become a reusable opinionated homelab later.

> **[OpenCode.md](OpenCode.md) is the single source of truth.** Architecture, locked decisions, service map, and verification live there. All options are verified against pinned `nixos-26.05`.

## What this repo is

- The complete NixOS configuration for the homelab server: `flake.nix`, `settings.nix`, `users.nix`, sops-encrypted `secrets/secrets.yaml`, `hosts/homelab`, and modular config under `modules/`.
- ZFS + disko storage (`/fast`, `/slow`), split-horizon DNS (AdGuard + WireGuard VPN), a full mail stack (simple-nixos-mailserver + Resend relay), the private-cloud tier (Nextcloud + Collabora + Immich + Vaultwarden), and a planned "feels like Netflix" media pipeline — all behind a minimal-exposure network (**25/tcp + 51820/udp only**).
- ~25 native NixOS services. One sanctioned container exception: Booklore.

## Status

**Deployed:** server `10.0.0.2`, gen ~82, full system closure builds with zero warnings.

| Area | Status |
|---|---|
| Foundation (flake, settings, users, secrets) | ✅ |
| Storage (ZFS, disko, `/fast` `/slow` layout) | ✅ |
| Networking (static IP, firewall, AdGuard, Kea, WireGuard 97 peers, ddclient, ACME, nginx, tunnel, DNSSEC) | ✅ |
| Mail (SNM + Resend, sieve, hardening) | ✅ verified green (mail-tester/MECSA/DANE) |
| Identity & Access (Authelia, nginx ACL, profile/QRs) | ✅ |
| Cloud Services (Nextcloud+Office, Collabora, Immich, Vaultwarden) | ✅ |
| Downloads & VPN (qBit/SAB/slskd + confinement) | ⬜ next milestone |
| Arr Stack (Sonarr/Radarr/…, Seerr, beets, soularr) | ⬜ |
| Media Players (Jellyfin, Navidrome, ABS, Booklore) | ⬜ |
| Smart Home (Home Assistant) | ⬜ |
| Monitoring & Backups (Beszel, Restic→B2) | ⬜ |
| Websites (Hugo, dnanu.de) | ⬜ |

Tracked in `TODO/` (one folder per project area).

## Agent tooling (opencode)

This repo ships an opencode configuration so AI agents work the way the project wants — **role-designed agents, a direct + PR-gated workflow, and one orchestrator (JOAT)**. See [AGENTS.md](AGENTS.md).

| Piece | Where | What it does |
|---|---|---|
| Main config | `opencode.json` | instructions, MCP servers, references, permissions |
| Agents | `.opencode/agent/` | JOAT (orchestrator), architect, builder, reviewer, verifier, deployer, troubleshooter — each with a default model, overridable per task |
| Commands | `.opencode/command/` | `/init`, `/task`, `/branch`, `/commit`, `/pr`, `/review`, `/deploy`, `/verify`, `/status`, `/update`, `/secrets` |
| Skills | `.opencode/skills/` | nixos-flake, sops-secrets, mail-stack, zfs-disko, deployment, verification, security-hardening, git-workflow |
| References | `@nixpkgs @snm @disko @sops-nix @nixos-anywhere @vpn-confinement` | pinned-channel verification sources |

**Workflow:** feature branch → work → PR → human merges → server pulls `main` → deploy. `main` is protected and always deployable.

MCP servers: **context7** (option lookup), **ssh-homelab** (`@fangjunjie/ssh-mcp-server` → 10.0.0.2, password via the `HOMELAB_SSH_PASSWORD` env var — see Memory.md), **playwright** (browser-verifying UIs). The two `npx`-based ones need `nodejs`/`npm` installed; the remote ones work without.

## Starting a session — `Init`

Launch opencode in this directory and type `/init`. It probes the environment (repo, toolchain, server, MCP health), asks a short batch of setup questions, and routes work across the agents — pausing for your approval at milestones.

Prereqs for a live session: `HOMELAB_SSH_PASSWORD` set in the shell **before** launching opencode (exported in fish via `~/.config/fish/conf.d/homelab.fish`).

## License

See [LICENSE](LICENSE).
