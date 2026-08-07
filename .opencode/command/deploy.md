---
description: Deploy main to the homelab server and rebuild (pull + nixos-rebuild switch), then smoke-test. Run after a PR merges, or on request.
agent: deployer
---

# Deploy

Deploy the current `main` to the homelab server (10.0.0.2) and rebuild.

Scope: $ARGUMENTS

1. Confirm main is at origin (pull locally first if needed).
2. Follow the deployment checklist: verify reachability, sync `/etc/nixos` on the server (`git pull origin main`), `nixos-rebuild switch --flake .#homelab`, roll back on failure.
3. Run the relevant §13 verification checks.
4. Report the new generation + any manual steps.
