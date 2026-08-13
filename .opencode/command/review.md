---
description: Review uncommitted changes (or a branch/PR) for bugs, security, structure, and public-safety before merging. Use for anything touching security, secrets, or exposure.
agent: reviewer
---

# Review

Review changes before they merge to main.

Scope: $ARGUMENTS (e.g. "git diff", "branch <name>", "PR #123")

1. Inspect: `git status --short`, `git diff` (staged + unstaged), and `git log origin/main..HEAD` for a branch.
2. Run the review checklist (secrets, exposure, TLS, DNS, VPN confinement, NixOS correctness against pinned 26.05, public-safety, SSH policy).
3. Report findings as a numbered list with severity (MUST-FIX / SHOULD-FIX / NICE-TO-HAVE), file:line, and a concrete fix.
4. Give a clear verdict: APPROVE / CHANGES REQUESTED / BLOCK.
