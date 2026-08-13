---
description: Report repo state, server health, and toolchain in one shot. Lightweight info-gathering.
agent: joat
---

# Status

Give a concise status report:

1. Git: current branch, `git status --short`, unpushed commits, last commit.
2. Server: reachable at 10.0.0.2? (`ssh -o BatchMode=yes -o ConnectTimeout=5 root@10.0.0.2 true`), current generation (`readlink /nix/var/nix/profiles/system`).
3. Toolchain: `node`/`npx`/`gh` present and authed?
4. Open PRs: `gh pr list`.

Scope: $ARGUMENTS
