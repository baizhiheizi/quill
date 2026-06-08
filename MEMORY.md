# Test Improver Memory

## Discovered Commands

### Build Commands
- `bun run build` - Build JS assets
- `bun run build:css` - Build CSS assets

### Test Commands
- `bin/rails test` - Run all tests (Minitest)
- `bin/rails test:system` - Run system tests (Capybara)
- `bin/rails zeitwerk:check` - Check Zeitwerk autoloading

### Lint Commands
- `bin/rubocop` - Ruby linting
- `bun run lint-check` - JavaScript/Prettier check
- `bun run lint` - Prettier write

### CI Commands
- `bin/ci` - Full CI pipeline (setup, rubocop, lint-check, tests, seeds)

### Coverage
- No explicit coverage command found. CI does not appear to generate coverage reports.

## Testing Notes

- **Framework**: Minitest (~> 5.25) with Capybara for system tests
- **Test location**: `test/` mirrors `app/` structure
- **Test naming**: `*_test.rb` pattern
- **Fixtures**: YAML fixtures in `test/fixtures/`
- **Helpers**: CommerceHelpers, NotifierHelpers, QuillBotStub available in all tests
- **ActiveJob**: Test helper `perform_all_jobs` available
- **Auth**: `sign_in(user)` helper creates Session for web tests; `api_headers(access_token)` for API tests
- **Tests cannot run locally** due to Arweave GraphQL API network restrictions in sandbox
- **MarkdownRenderService / RichTextRenderService**: Pure services (no DB). `FastImage.size` may return nil for unreachable URLs; tests assert on wrapping behavior, not on width/height. iframe-src whitelist = YouTube only.
- **PreOrder**: AASM state machine has `drafted → paid` and `drafted → expired` events. `pay!` fires `broadcast_to_views` as after_commit (stub with `define_singleton_method(:broadcast_to_views) { }` in tests). `setup_attributes` callback auto-fills `follow_id`, `trace_id` (via `item.payment_trace_id payer`), `memo` (urlsafe base64, no padding, no `+`/`/`), `payee_id` (= QuillBot.client_id), and `asset_id` (from item).
- **PreOrder decoded_memo keys**: `t` (BUY/REWARD), `a` (article uuid), `l` (collection uuid for buy_collection), `f` (follow_id).
- **`safeoutputs create_pull_request`**: Returns a patch/bundle path when the bridge is in patch mode rather than opening a real PR on the remote. The PR may not appear in `list_pull_requests` until the bridge pushes the branch. The 2026-06-07 run's PR #1542 was opened and later closed (not merged).

## Testing Backlog

1. **[HIGH] Article Authorization** - Access control edge cases (blocked users, self-purchase, mixed free/paid) beyond policy layer
2. **[HIGH] Early Reader Detection** - `collect_early_readers` grouping with same reader multiple orders and currency mixing
3. ~~[MEDIUM] Pre-Order State Machine~~ - ✅ Addressed 2026-06-08 (branch `test-assist/pre-order-state-machine`)
4. **[LOW] Collection Revenue Distribution** - `distribute_collection_order!` minimal coverage beyond basic buy flow

## Work in Progress

- Draft PR prepared: "Add PreOrder state machine and validation tests" (branch `test-assist/pre-order-state-machine`, 21 tests total, 18 new, rubocop clean). PR creation via `safeoutputs create_pull_request` returned a patch bundle rather than opening a real PR — the previous run's PR #1542 used the same workflow and was successfully opened, so this may be a transient bridge issue. Monthly activity issue #1517 has been updated with the draft.

## Completed Work

### 2026-06-08
- Added 18 tests to `test/models/pre_order_test.rb` (3 → 21 total): AASM transitions (drafted/paid/expired, invalid transitions), validations (amount > 0, trace_id, memo, author-as-payer), `setup_attributes` callback (follow_id, asset_id, payee_id), `decoded_memo` for buy_article/reward_article/buy_collection + urlsafe base64 invariant, `to_param`, `amount_tag`, `broadcast_to_views` after_commit
- Rubocop clean on the updated file
- Updated Monthly Activity issue #1517 with this run's entry

### 2026-06-07
- Added 21 tests for `MarkdownRenderService` (kramdown rendering, iframe whitelist including YouTube www/non-www/javascript:/empty src, link target=_blank, paragraph/table classes, comment-link rewriting, image photoswipe wrapping, blob URL extension stripping)
- Added 17 tests for `RichTextRenderService` (mirrors markdown suite + ActionText::Content coercion + shared IFRAME_SRC_WHITE_LIST_REGEX constant)
- Rubocop clean on both new test files
- PR #1542 opened then closed (not merged) on 2026-06-07

### 2026-06-01
- PR #1516 (merged): CiterReference model tests + order distribution with references
- PR #1519 (merged): Payment memo edge cases + policy tests (Order, Collection, Comment) + blocked-buyer refund fix

## Last Run

- 2026-06-08 - PreOrder state machine tests added (18 new tests, branch `test-assist/pre-order-state-machine`); Monthly Activity issue #1517 updated
