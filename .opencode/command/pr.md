---
description: Push the current feature branch and open a pull request against main for review. The human merges.
agent: joat
---

# PR

Push the current feature branch and open a PR against `main`.

PR title / body hint: $ARGUMENTS

1. Verify you're on a feature branch (not main).
2. Inspect status, diff, and the base branch (`main`). Review for public-safety (no secrets).
3. `git push -u origin <branch>`, then `gh pr create --base main --title "<title>" --body "<summary>"`.
4. Body: what changed, what was verified, any manual steps (the "1% manual" list).
5. Report the PR URL. Tell the human it's ready to review/merge.
