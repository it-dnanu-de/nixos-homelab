---
description: Stage and commit the current changes with a descriptive message. Run on a feature branch; never commit directly to main.
agent: builder
---

# Commit

Commit the current working-tree changes on the current feature branch.

Message hint / scope: $ARGUMENTS

1. Inspect `git status` and `git diff` first. Stage only intended files — never secrets or Memory.md.
2. Write a concise, descriptive commit message (imperative, ~50-char subject; body = what + why + verification).
3. Commit. Do NOT push to main — if on main, say so and switch to a feature branch first.
