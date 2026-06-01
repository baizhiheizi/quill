# Test Improver memory

> Persistent state for local `/test-assist` and `/test-improver` runs.
> Do not store secrets. Verify against `gh` and the repo before acting on stale entries.
>
> **Full `/test-improver` runs:** memory updates must be committed on the run branch and included in the draft PR for that run (including memory-only runs).

## build/test/coverage commands

Validated against `AGENTS.md`, `config/ci.rb`, and `.github/workflows/check.yml` on **2026-06-01**.

| Purpose | Command | Notes |
|---------|---------|-------|
| Full CI locally | `bin/ci` | setup, rubocop, `bun run lint-check`, `bin/rails test`, `db:seed:replant` |
| Tests | `bin/rails test` | Minitest; 178 runs / 294 assertions pass locally |
| System tests | `bin/rails test:system` | Optional; commented out in CI |
| Zeitwerk | `bin/rails zeitwerk:check` | Passes locally |
| Ruby lint | `bin/rubocop` | |
| JS lint | `bun run lint-check` | Prettier check on `app/javascript` |
| DB prep | `bin/rails db:prepare` | main + cable + queue databases |

**Coverage:** No SimpleCov, Codecov, or Coveralls in CI. Measure impact via targeted `bin/rails test` runs unless tooling is added.

**Framework:** Minitest + fixtures in `test/fixtures/`; Capybara for system tests per AGENTS.md.

**Quirks:** PostgreSQL required; `RAILS_ENV=test` for tests. Tests run successfully locally (unlike GitHub Agentic Workflow sandbox with Arweave network restrictions).

## testing notes

- `CommentPolicy#create?` takes an **Article** as `record`, not a Comment; `vote?` takes a Comment.
- `Collection#published?` is `uuid.present?`, not state-based — policy tests must reflect this.
- `CommerceHelpers#build_payment_memo` supports `citer:` for CITE payment memos.
- Blocked buyer payments: `Payment#generate_article_order!` must raise `ActiveRecord::RecordInvalid.new(self)` (not a string) for refund rescue to work.
- Policy tests follow `ArticlePolicyTest` pattern with `with_quill_bot_stub` + `create_buy_order!`.

## maintainer priorities

No specific priorities communicated yet (June 2026 monthly issue #1517).

## testing backlog

1. **[CRITICAL] Orders::DistributeService** — Dedicated service tests; collection revenue split, cross-currency early readers, minimum amount thresholds beyond order_test integration.
2. **[HIGH] Article Authorization** — Controller/integration edge cases beyond policy layer.
3. **[HIGH] Early Reader Detection** — Same reader multiple orders, currency mixing in `collect_early_readers`.
4. **[MEDIUM] Pre-Order State Machine** — `PreOrder` AASM transitions and validations.
5. **[MEDIUM] MarkdownRenderService** — XSS and formatting correctness.
6. **[LOW] Collection revenue distribution** — `distribute_collection_order!` edge cases.

**Addressed (pending merge):** Payment memo validation (#1519), CiterReference + reference revenue distribution (#1516), Order/Collection/Comment policies (#1519).

## backlog cursor

Next focus: `Orders::DistributeService` dedicated test file after #1516 merges.

## work in progress

None — PR #1519 pushed and awaiting review.

## completed work

| PR | Status | Summary |
|----|--------|---------|
| #1516 | Open (draft) | CiterReference model tests + order reference revenue distribution |
| #1519 | Open (draft) | Payment memo edge cases, Order/Collection/Comment policy tests, blocked-buyer refund fix |

## last task runs

| Task | Last run (UTC) |
|------|----------------|
| 1 | 2026-06-01 12:54 |
| 2 | 2026-06-01 12:54 |
| 3 | 2026-06-01 12:54 |
| 4 | 2026-06-01 12:54 |
| 5 | — |
| 6 | — |
| 7 | 2026-06-01 12:54 |

## monthly summary — checked off by maintainer

_(Lines removed from Suggested Actions when maintainer checked them off in the monthly issue.)_
