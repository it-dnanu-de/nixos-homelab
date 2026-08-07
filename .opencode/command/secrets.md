---
description: Open the sops-encrypted secrets/secrets.yaml for editing (requires the age key). Use to add or change a secret.
agent: builder
---

# Secrets

Edit the sops-encrypted secrets file for the homelab.

Target secret / action: $ARGUMENTS

1. Locate the age key (USB / password manager — do NOT copy it into the repo).
2. `sops secrets/secrets.yaml` (or `sops edit`). On the server: `sops /etc/nixos/secrets/secrets.yaml`.
3. Add/change the requested secret. Update the secrets inventory in OpenCode.md §7 if you add a new key.
4. Never commit decrypted values. The encrypted file is safe to commit.
