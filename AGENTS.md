# AGENTS — how this repo's AI agents work

> One page. The agent system is the human's interface to the homelab. It is deliberately small: role-designed agents, a direct + PR-gated workflow, and one orchestrator (JOAT) that coordinates.

## The agent set

| Agent | Default model | Job |
|---|---|---|
| **JOAT** (primary) | DeepSeek V4 Flash | Orchestrator + docs owner + generalist. The agent you actually talk to. Coordinates the role agents, owns README/AGENTS/Changes/TODO, opens PRs. |
| **architect** | Kimi K3 | Plans, architecture, breaking down milestones, hard problems. Writes plans, not code. |
| **builder** | DeepSeek V4 Pro | Executes plans: NixOS modules, service config, multi-file changes. Writes + verifies code. |
| **reviewer** | Kimi K3 | Security + quality review before merge. Enforces the port table, sops hygiene, public-safety. |
| **verifier** | DeepSeek V4 Flash | Confirms options/packages exist in pinned `nixos-26.05` before they're used. |
| **deployer** | DeepSeek V4 Pro | Server rebuild/deploy on 10.0.0.2 + smoke-test. |
| **troubleshooter** | GLM 5.2 | Debugging when something breaks. |

Models are a lever: each role has a default, but JOAT picks the model per task. Agents are the contract; models are the cost/quality tradeoff.

## Workflow: direct + PR-gated

```
main (protected) ──► server auto-pulls ──► deployable always
   ▲
   │ merge (human)
   │
feat/<topic> branch ──► work ──► PR ──► review ──► merge
```

- **Small change**: JOAT does it directly on a feature branch → PR → human merges.
- **Big milestone**: architect writes a short plan → human approves → builder executes → PR → human merges.
- **Risky (security/secrets)**: reviewer must sign off before merge.
- **Server work**: deployer runs after the PR lands on main.
- Never commit to `main` directly. `main` is protected. The server pulls only `main`.

## The role of the .md files

| File | Owner | Purpose |
|---|---|---|
| `OpenCode.md` | architect | Architecture, locked decisions, service map — the source of truth. |
| `README.md` | JOAT | Human-facing: what this is, status, how to use it. |
| `AGENTS.md` | JOAT | This file — how the agent system works. |
| `Changes.md` | JOAT | Session log; folded into OpenCode.md at session end. |
| `TODO/` | JOAT | Work tracker, one folder per project area. |
| `Memory.md` | gitignored | Credentials + operational facts, loaded each session, never committed. |

## Operating rules (from OpenCode.md)

1. **OpenCode.md is the single source of truth.** Read the **Project Vision** section first — three repos (nixos=archived, nixos-homelab=v1 personal, v2=fork for everyone). Build exactly what it specifies, nothing more.
2. **✅ LOCKED** = decided, don't revisit. **⚠️ VERIFY** = check against pinned `nixos-26.05` before use.
3. **Native NixOS modules preferred for infra; Docker containers where decided** (media managers + request services via `virtualisation.oci-containers`, backend docker). VPN isolation always via VPN-Confinement netns.
4. **Zero open ports** except 25/tcp + 51820/udp (WireGuard). Everything else through VPN/tunnel/netns.
5. **Secrets via sops-nix.** Memory.md is gitignored. The repo is public-safe.
6. **SSH password auth stays enabled** — never disable it (human ruling).
7. **Commit after every coherent change.** Feature branches + PRs. Human merges.
8. **Accounts are declarative** (occ/CLI oneshots on first install, idempotent).
