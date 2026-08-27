# Contracts: Design-System Contracts Index

> Phase 1 of `/speckit.plan`. The Quill 011-comprehensive-ui-refactor feature is a presentational refactor; the "contracts" here are not external API contracts but the in-app contracts the design system exposes to every view, partial, Stimulus controller, and lint rule.

## Files in this directory

| File | What it defines |
|---|---|
| [`tokens.md`](./tokens.md) | Color, typography, radius, spacing, motion tokens + their light/dark values + the rule that no view may hardcode a raw hex. |
| [`primitives.md`](./primitives.md) | The list of primitives, the partial that backs each, the locals each partial accepts, and the rule that no view may introduce a new variant without registering it. |
| [`lint-rules.md`](./lint-rules.md) | The exact rules enforced by `bin/lint-design-system`, with one example violation + one example compliance per rule. |

## How to use these contracts

When implementing a view (or a new partial):

1. Look up the primitive you need in [`primitives.md`](./primitives.md); use the listed partial via its helper.
2. If you need a new color, type ramp, or component, register it in [`tokens.md`](./tokens.md) or [`primitives.md`](./primitives.md) **first** — then use it.
3. If your change introduces a new rule the lint script should catch, add it to [`lint-rules.md`](./lint-rules.md) and to `lib/design_system/lint.rb` in the same PR.
4. If the new primitive is used by 3+ views, extract it as a partial under `app/views/shared/`; if it's used by 2 views, keep it inline but document its contract here.

When reviewing a PR:

1. Does the PR add any token or primitive not listed here? If yes, request that it be registered before merging.
2. Does the PR introduce a new hex color, a new hand-rolled SVG, or a `tag-style-*` class? If yes, `bin/lint-design-system` should fail; the PR is not ready.
3. Does the PR touch any of the 50+ surfaces listed in `plan.md` §"Files Touched" without using a primitive? If yes, request refactoring to a primitive first.

## Versioning

These contracts are versioned with the Quill app. A breaking change (renaming a token, removing a primitive, changing a partial's required locals) requires:

- An entry in `CHANGELOG.md`.
- A migration note in `AGENTS.md`.
- A mention in the next `/speckit.plan` run.

Non-breaking additions (new primitives, new optional locals, new tokens) require only the addition here + a mention in `CHANGELOG.md`.