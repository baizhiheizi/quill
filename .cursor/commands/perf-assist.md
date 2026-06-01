---
name: /perf-assist
description: On-demand performance work (Perf Improver command mode)
---

# /perf-assist

On-demand Perf Improver — focused performance work from your instructions (local equivalent of GitHub `/perf-assist <instructions>`).

## Input

Everything after `/perf-assist` on the same line is **instructions**. If empty, ask:

> What should Perf Improver focus on? Describe the area, symptom, or goal (e.g. slow article show page, N+1 query, CI duration). For a full scheduled-style run, use `/perf-improver` instead.

Do not proceed without clear instructions unless the user answers.

## Steps

1. Read [AGENTS.md](AGENTS.md) for project conventions and verify commands.
2. Read and update [.cursor/perf-improver/memory.md](.cursor/perf-improver/memory.md) at start and end of the run.
3. Follow **Command Mode** in [.cursor/skills/perf-improver/SKILL.md](.cursor/skills/perf-improver/SKILL.md) using the user's instructions.
4. Apply skill **Guidelines**: measure before/after, run `bin/rubocop` / `bun run lint-check` / tests when changing code, 🤖 disclosure on any `gh` comment or PR.
5. Use `gh` for draft PRs/issues only when the user's task requires it (title prefix `[perf-improver]`).
6. **Memory and PRs:** If you create or update a PR, commit [.cursor/perf-improver/memory.md](.cursor/perf-improver/memory.md) in that same PR. If you only investigate and do not open a PR, you may update memory locally and tell the user it is uncommitted unless they ask to commit it.
7. **Stop** when instructions are done — do not run Non-Command Mode round-robin, full self-contained lifecycle, or Task 7 unless the user asked for them.

## Guardrails

- No secrets in commits or memory.
- Do not edit protected manifest files (see skill) without explicit user approval.
- Do not fall through to `/perf-improver` workflow in the same run.
- Do not leave unrelated dirty files; report `git status` if the worktree is not clean when done.
