---
name: /perf-improver
description: Full self-contained Perf Improver run (branch, PR, memory, cleanup)
---

# /perf-improver

End-to-end Perf Improver run: preflight, round-robin Tasks 1–6 (2–3 per run), Task 7, memory committed in the run PR, GitHub updates, clean worktree.

Follow **Self-contained run contract** and **Non-Command Mode** in [.cursor/skills/perf-improver/SKILL.md](.cursor/skills/perf-improver/SKILL.md). This command is authoritative for full runs.

## Prerequisites

- `gh auth login` and network access
- PostgreSQL if Task 3 may run tests
- **Clean worktree** on the branch you start from (no unrelated uncommitted changes)

## Self-contained lifecycle (mandatory order)

### 1. Preflight

```bash
gh auth status
git branch --show-current    # record START_BRANCH
git status --short           # must be empty; if not, stop and ask user to stash/commit
git fetch origin             # when safe
```

- Do not stash, reset, or discard user changes without explicit approval.
- Pre-check open PR cap:

  ```bash
  MAX_OPEN_PRS=8
  COUNT=$(gh pr list --state open --search 'in:title "[perf-improver]"' --json number --jq 'length')
  ```

  If `COUNT >= MAX_OPEN_PRS`, do not open **new** perf PRs; you may still maintain existing PRs (Task 4) and update the monthly issue (Task 7).

### 2. Branch

- Read [AGENTS.md](AGENTS.md) and [.cursor/perf-improver/memory.md](.cursor/perf-improver/memory.md); verify stale entries against `gh` and the repo.
- If maintaining an existing `[perf-improver]` PR, check out that PR branch and skip creating a new branch.
- Otherwise create from updated default branch:

  ```bash
  git checkout main && git pull origin main   # or repo default branch
  git checkout -b perf-improver/YYYY-MM-DD-<short-topic>
  ```

### 3. Execute workflow

- Round-robin: 2–3 tasks least recently run (per memory) + **Task 7 always**
- Identify as **Perf Improver (local Cursor)** in PRs and comments
- Respect skill limits: max 4 new PRs/issues per run, max 10 comments, max 3 issue comments in Task 5

### 4. Update and commit memory (required)

- Update [.cursor/perf-improver/memory.md](.cursor/perf-improver/memory.md) (commands, backlog, task timestamps, WIP, completed work).
- Stage **only** files changed by this run.
- **Commit memory in the same PR** as code changes. If the run only updated memory/issues/comments with no product code, still commit memory on the run branch.
- Do not commit profiler output, benchmark artifacts, or temp files.

### 5. Push and draft PR

```bash
git push -u origin <run-branch>
gh pr create --draft --title "[perf-improver] <summary>" \
  --label automation --label performance --body "<see skill PR body checklist>"
```

PR body must include: run summary, tasks completed, issues/comments touched, memory sections changed, performance evidence, test/lint status, cleanup status.

- Create or update the draft PR **before** Task 7 monthly issue update so the issue can link to the PR.

### 6. Task 7 and GitHub

- Update `[perf-improver] Monthly Activity {YYYY-MM}` (label `performance`) when work was done; link the run PR in Run History.
- Skip monthly issue update only if nothing was done this run.

### 7. Cleanup

```bash
git status --short
```

- If clean: `git checkout <START_BRANCH>` when different from run branch.
- If not clean: report exact leftover paths and why; do not hide dirty state.
- Never merge PRs yourself.

## Guardrails

- No secrets in commits or memory.
- Do not edit protected manifest files (see skill) without explicit user approval.

For focused work without a full lifecycle, use `/perf-assist <instructions>` instead.
