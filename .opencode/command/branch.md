---
description: Create a feature branch for the given work and switch to it. Run before starting a change so main stays clean.
agent: joat
---

# Branch

Create a feature branch and switch to it.

1. `git checkout main && git pull` (ensure up to date).
2. `git checkout -b <branch>` — name it `feat/<topic>` (or `fix/<topic>` for fixes).
3. Confirm you're on the new branch.
4. Report the branch name.

Branch name: $ARGUMENTS
