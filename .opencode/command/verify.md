---
description: Run the §13 verification suite against the running homelab server and report results as a checklist.
agent: deployer
---

# Verify

Run the verification suite from OpenCode.md §13 against the homelab server.

Scope: $ARGUMENTS

Checks: `zpool status` · `dig @10.0.10.2 mail.dnanu.de` (-> 10.0.10.11 mail container) · `dig mail.dnanu.de @1.1.1.1` (-> home IP) · `dig vpn.dnanu.de @1.1.1.1` (-> home IP) · inbound SMTP (`swaks --to hey@dnanu.de`) · iOS send -> confirm delivery · `curl -I https://cloud.nanulab.de` + `media.nanulab.de` over VPN/LAN · guest IP -> 403 on vhosts · catch-all 404 · **zone isolation** (guest->container denied, frontend->backend allowed) · qBittorrent IP-leak test · `restic check` · lid-close test · `systemctl --failed` empty · DNSSEC `dig +dnssec +adflag dnanu.de @9.9.9.9`.

Skip tests for services not yet installed. Report each as PASS / FAIL / SKIPPED with evidence.
