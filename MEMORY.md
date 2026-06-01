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

## Testing Backlog

1. **[CRITICAL] Order Distribution Revenue Splitting** - `app/services/orders/distribute_service.rb` needs edge case tests
2. **[CRITICAL] Payment Memo Validation** - `app/models/payment.rb` memo parsing/routing
3. **[HIGH] Article Authorization** - Access control edge cases
4. **[HIGH] Early Reader Detection** - `collect_early_readers` grouping logic
5. **[MEDIUM] Missing Policy Tests** - collection_policy, comment_policy, order_policy
6. **[MEDIUM] Pre-Order State Machine** - `app/models/pre_order.rb`
7. **[MEDIUM] Markdown/Rich Text Rendering** - XSS protection
8. **[LOW] Collection Revenue Distribution** - `distribute_collection_order!`

## Work in Progress

- PR created: "Add tests for CiterReference and order distribution with references"
- Issue created: Monthly Activity 2026-06

## Completed Work

### 2026-06-01
- Added comprehensive tests for CiterReference model (polymorphic associations, uniqueness validation)
- Added tests for order distribution with references (reference revenue, proportional sharing, minimum threshold, idempotency)
- Created draft PR with 180+ lines of new tests
- Created Monthly Activity issue

## Last Run

- 2026-06-01 - Initial run complete
