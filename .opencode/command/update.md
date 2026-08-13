---
description: Run the quarterly nix flake update workflow (deliberate, human-approved). Architect reviews the bump.
agent: architect
---

# Update

Run the quarterly flake update workflow from OpenCode.md §14.

1. On the server (where nix lives): `cd /etc/nixos && nix flake update`.
2. Review the `flake.lock` diff — list version bumps, flag concerning jumps.
3. Build and test before switching: `nixos-rebuild dry-run --flake .#homelab`.
4. Report the summary; wait for human approval before switching. Rollback = boot menu / flake.lock history. No unattended upgrades.

Scope: $ARGUMENTS
