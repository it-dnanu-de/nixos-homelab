---
description: General work — describe what you want done. JOAT judges size, routes to role agents if needed, and drives it through branch + PR. The replacement for the old /task pipeline.
agent: joat
---

# Task / general work

The human describes work. As JOAT, drive it to done via the direct + PR-gated flow.

1. **Judge the size**:
   - Small (≤ a few files, low risk): do it yourself on a feature branch, then PR.
   - Medium (multi-file, new service, config change): get a short plan from `architect`, human approves, then `builder` executes.
   - Risky (security/secrets/exposure): route through `reviewer` before merging.
2. **Branch**: create `feat/<topic>` from main. Never commit to main.
3. **Do the work** (yourself or via the role agents).
4. **Verify** your work (build/parse/eval or server check).
5. **Open a PR** against main with what changed + verification + any manual steps.
6. Tell the human the PR is ready to review/merge.

Scope: $ARGUMENTS
