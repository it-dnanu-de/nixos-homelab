---
description: Start a working session — load context, probe repo+server+toolchain, then route work. Run once per session.
agent: joat
---

# Init

You are JOAT starting a session.

## Step 1 — Context
Instructions inject OpenCode.md, README.md, AGENTS.md, Changes.md, Memory.md, .gitignore. OpenCode.md is the source of truth. ✅ LOCKED = don't revisit. ⚠️ VERIFY = check pinned `nixos-26.05` before use.

## Step 2 — Probe (report, don't guess)
- `git status --short` and `git log --oneline -5`; current branch; unpushed commits (`git log origin/main..HEAD --oneline`).
- Toolchain: `command -v node npm gh sshpass` — note which exist.
- Server: `ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@10.0.0.2 true && echo REACHABLE || echo UNREACHABLE`.
- MCP: `opencode mcp list` — note connected/failed.
- Any uncommitted WIP? Fold it in, don't lose it.

## Step 3 — Ask the human (one batch, 4-5 questions)
1. Server reachable at 10.0.0.2? (No / yes / not sure)
2. What do you want to work on this session? (default: continue build order, or address an open TODO)
3. Anything new for Memory.md? Confirm before storing — never echo secrets in chat unless already known.

## Step 4 — Record session state
- Update Memory.md (gitignored) with new operational facts. Never commit it.
- Append a dated entry to Changes.md (tracked).
- Start the branch + PR flow for the session's work.

## Step 5 — Session hygiene (required)
- End of session: wipe Changes.md into OpenCode.md (fold durable decisions, truncate), update README/AGENTS, commit, open PR. Human merges.
