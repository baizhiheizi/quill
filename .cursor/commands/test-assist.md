---
name: /test-assist
description: On-demand testing work (Test Improver command mode)
---

# /test-assist

On-demand Test Improver — focused test work from your instructions (local equivalent of GitHub `/test-assist <instructions>`).

## Input

Everything after `/test-assist` on the same line is **instructions**. If empty, ask:

> What should Test Improver focus on? Describe the area, bug, or test goal (e.g. add regression test for Order distribution, fix flaky job test). For a full scheduled-style run, use `/test-improver` instead.

Do not proceed without clear instructions unless the user answers.

## Steps

1. Read [AGENTS.md](AGENTS.md) for project conventions and test layout.
2. Read and update [.cursor/test-improver/memory.md](.cursor/test-improver/memory.md) at start and end of the run.
3. Follow **Command Mode** in [.cursor/skills/test-improver/SKILL.md](.cursor/skills/test-improver/SKILL.md) using the user's instructions.
4. Apply skill **Guidelines**: run `bin/rubocop` / `bun run lint-check` / `bin/rails test` when changing code; never weaken tests to force green; 🤖 disclosure on any `gh` comment or PR.
5. Use `gh` for draft PRs/issues only when the user's task requires it (title prefix `[test-improver]`).
6. **Stop** when instructions are done — do not run Non-Command Mode round-robin or Task 7 unless the user asked for them.

## Guardrails

- No secrets in commits or memory.
- Do not edit protected manifest files (see skill) without explicit user approval.
- Do not fall through to `/test-improver` workflow in the same run.
