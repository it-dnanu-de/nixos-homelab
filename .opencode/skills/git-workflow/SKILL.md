---
name: git-workflow
description: Use for any git operation in this repo — branching, committing, PRs. Enforces the branch + PR gate, commit-after-every-change, and the public-safe rule (no secrets in history).
---

# Git Workflow

Repo: `https://github.com/it-dnanu-de/nixos-homelab` (public). Single source of truth = OpenCode.md.

## Branching (mandatory)
- `main` is the trunk, **protected** — no direct pushes. The server auto-pulls `main`, so it must stay deployable.
- Every change happens on a feature branch: `feat/<topic>` or `fix/<topic>`, cut from up-to-date `main`.
- The human merges PRs into main.

## Conventions
- **Commit after every coherent change.** Everything is version controlled so any state can be reverted.
- Commits represent meaningful, revertable checkpoints. Never commit broken or unverified work.
- Commit on the feature branch; the PR carries the branch to main.

## Public-safe rule (critical)
The repo is public-safe. Before `git add`:
1. `git status` + `git diff` review.
2. Confirm no passwords, tokens, API keys, age keys, or private keys staged.
3. `Memory.md` is gitignored (holds credentials) — never `git add -f` it.

## Commit message style
- Imperative subject, ~50 chars: "Fix postfix relay auth", "Add nextcloud office app".
- Body: what + why + verification performed.

## PR flow
- `git push -u origin <branch>`, then `gh pr create --base main`.
- PR body: what changed, what was verified, any manual steps (the "1% manual" install list).
- Human reviews + merges. After merge, the server pulls main on the next deploy.

## Session hygiene (OpenCode.md)
- Each session: load OpenCode.md, README.md, AGENTS.md, .gitignore, Changes.md, Memory.md.
- Update README.md, AGENTS.md, .gitignore, Changes.md, Memory.md.
- Changes.md is temporary: wipe it at end of session and fold the changes into OpenCode.md.
