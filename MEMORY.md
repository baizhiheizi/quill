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

## Testing Backlog

1. **[HIGH] Article Authorization** - Access control edge cases (blocked users, self-purchase, mixed free/paid) beyond policy layer
2. **[HIGH] Early Reader Detection** - `collect_early_readers` grouping with same reader multiple orders and currency mixing
3. **[MEDIUM] Pre-Order State Machine** - `PreOrder` state transitions and validations (only 3 tests exist)
4. **[LOW] Collection Revenue Distribution** - `distribute_collection_order!` minimal coverage beyond basic buy flow

## Work in Progress

- PR submitted: "Add tests for MarkdownRenderService and RichTextRenderService" (branch `test-assist/markdown-rich-text-render-service-tests`, 38 tests, rubocop clean)

## Completed Work

### 2026-06-07
- Added 21 tests for `MarkdownRenderService` (kramdown rendering, iframe whitelist including YouTube www/non-www/javascript:/empty src, link target=_blank, paragraph/table classes, comment-link rewriting, image photoswipe wrapping, blob URL extension stripping)
- Added 17 tests for `RichTextRenderService` (mirrors markdown suite + ActionText::Content coercion + shared IFRAME_SRC_WHITE_LIST_REGEX constant)
- Rubocop clean on both new test files
- Updated Monthly Activity issue for June 2026 with the new run

### 2026-06-01
- PR #1516 (merged): CiterReference model tests + order distribution with references
- PR #1519 (merged): Payment memo edge cases + policy tests (Order, Collection, Comment) + blocked-buyer refund fix

## Last Run

- 2026-06-07 - MarkdownRenderService/RichTextRenderService tests added; PR queued via safeoutputs (awaiting branch push)
