# Tasks: Global Mixin API Rate Gating

**Input**: Design documents from `/specs/007-mixin-api-rate-gate/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/mixin-api-gate.md, quickstart.md

**Tests**: Included per Quill Constitution §II — gate and client wrapper are non-trivial infrastructure with retry/backoff behavior.

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Maps to spec.md user stories (US1–US4)
- Include exact file paths in descriptions

## Path Conventions

Rails monolith — library code in `app/libs/mixin_api/`, tests in `test/libs/mixin_api/`, factory wiring in existing bot modules.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Directory structure and tunable configuration before gate implementation

- [x] T001 Create `app/libs/mixin_api/` directory for gate library files
- [x] T002 Add `mixin_api_gate` section (enabled, scopes, backoff, interactive_max_wait_seconds) to `config/settings.yml` per `specs/007-mixin-api-rate-gate/research.md` §6

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core gate, client wrapper, and factory — MUST complete before any user story wiring

**⚠️ CRITICAL**: No factory integration until this phase passes tests

- [x] T003 Implement `MixinApi::Gate` in `app/libs/mixin_api/gate.rb` (`acquire`, `record_throttle`, `release_success`, `backoff_remaining`, `enabled?`; `Rails.cache` state; per-scope `Mutex`; structured `Rails.logger.warn` on throttle)
- [x] T004 Implement `MixinApi::RateLimitedClient` in `app/libs/mixin_api/rate_limited_client.rb` (wrap `get`/`post`/`fetch_get`/`fetch_post`/`fetch_post_array`; retry only `MixinBot::RateLimitError` / `#throttle?`; pass through all other gem errors)
- [x] T005 Implement `MixinApi.wrap` factory in `app/libs/mixin_api/gate.rb` (swap `@client` on `MixinBot::API`; honor `Gate.enabled?`; accept `scope:` and `mode:` kwargs)
- [x] T006 [P] Create `test/libs/mixin_api/gate_test.rb` covering proactive spacing, `retry_after` honor, exponential backoff cap, scope isolation, and `enabled: false` bypass (stub `Rails.cache`, use `MixinBot::RateLimitError.new(...)`)
- [x] T007 [P] Create `test/libs/mixin_api/rate_limited_client_test.rb` covering background retry on 429, `:interactive` re-raise after max wait, and `NotFoundError` pass-through without retry (fake inner client)

**Checkpoint**: `bin/rails test test/libs/mixin_api/` passes; gate handles only `#throttle?` errors

---

## Phase 3: User Story 1 — Payment Ingestion Survives Rate Limits (Priority: P1) 🎯 MVP

**Goal**: Snapshot polling backs off on 429, worker stays alive, no payment gaps

**Independent Test**: Stub client raises `RateLimitError` then succeeds; poll loop / wrapped client retries without crash; offset unchanged until success

### Implementation for User Story 1

- [x] T008 [US1] Wire `MixinApi.wrap(api, scope: :quill_bot, mode: :background)` into `app/libs/quill_bot.rb` after `MixinBot::API.new`
- [x] T009 [US1] Add `MixinBot::RateLimitError` to rescue list alongside existing errors in `app/models/mixin_network_snapshot.rb` `#poll` (defense-in-depth)
- [x] T010 [P] [US1] Add background-mode indefinite-retry scenario in `test/libs/mixin_api/rate_limited_client_test.rb` simulating `safe_snapshots`-style GET path

**Checkpoint**: QuillBot REST calls gated; snapshot poll no longer crashes production on 429

---

## Phase 4: User Story 2 — All Mixin Callers Share One Global Gate (Priority: P2)

**Goal**: Every Mixin REST entry point uses the gate; scopes are independent

**Independent Test**: `revenue_bot` throttle does not block `quill_bot`; per-user scope uses separate cache keys

### Implementation for User Story 2

- [x] T011 [P] [US2] Wire `MixinApi.wrap(api, scope: :revenue_bot, mode: :background)` into `app/libs/revenue_bot.rb` after `MixinBot::API.new`
- [x] T012 [P] [US2] Wire `MixinApi.wrap(mixin_api, scope: "user:#{uuid}", mode: :background)` into `app/models/mixin_network_user.rb` `#mixin_api`
- [x] T013 [US2] Add cross-scope independence and fair-spacing assertions in `test/libs/mixin_api/gate_test.rb` (`quill_bot` vs `revenue_bot` vs `user:<uuid>`)

**Checkpoint**: All three factory integration points from `contracts/mixin-api-gate.md` §4 are wired

---

## Phase 5: User Story 3 — Transfer and Settlement Continue After Rate Limits (Priority: P2)

**Goal**: Transfers remain retryable after 429; no duplicate on-chain transactions

**Independent Test**: Transfer stub raises `RateLimitError` on `create_safe_transfer`; transfer stays unprocessed; succeeds on retry with same `trace_id`

### Implementation for User Story 3

- [x] T014 [US3] Add RateLimitError retry test in `test/models/transfer_test.rb` (stub `QuillBot.api.create_safe_transfer` to 429 then succeed; assert `processed_at` nil until success)
- [x] T015 [US3] Audit `app/models/transfer.rb` `#process_safe_transfer!` and `#process_all!` — ensure `MixinBot::RateLimitError` is not swallowed as generic success; adjust rescue flow only if transfer incorrectly marks processed on 429

**Checkpoint**: Transfer settlement survives rate limits without duplicate `request_id`/`trace_id` submissions

---

## Phase 6: User Story 4 — Operators Can Observe Rate-Limit Health (Priority: P3)

**Goal**: Structured logs distinguish throttle/backoff from crashes

**Independent Test**: Trigger `record_throttle`; log line contains `scope=`, `verb=`, `path=`, `backoff=`; no secrets

### Implementation for User Story 4

- [x] T016 [P] [US4] Add log-format assertion in `test/libs/mixin_api/gate_test.rb` using `Rails.logger` stub — verify `[MixinApi::Gate]` warn output matches `contracts/mixin-api-gate.md` §1

**Checkpoint**: Operators can grep `MixinApi::Gate` in logs to diagnose rate-limit incidents

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Interactive OAuth UX, lint, full suite, manual validation

- [x] T017 Use `:interactive` mode for synchronous OAuth calls (`oauth_token`, `me`) in `app/models/concerns/authenticatable.rb` via scoped wrap or dedicated rate-limited client
- [x] T018 Handle `MixinBot::RateLimitError` in `app/controllers/sessions_controller.rb` with retryable flash message
- [x] T019 [P] Add user-visible rate-limit strings to `config/locales/en.yml` and `config/locales/zh-CN.yml` (only if no existing copy covers OAuth retry)
- [x] T020 Run `bin/rubocop` on `app/libs/mixin_api/`, `app/libs/quill_bot.rb`, `app/libs/revenue_bot.rb`, and touched model/controller files
- [x] T021 Run `bin/rails test test/libs/mixin_api/ test/models/transfer_test.rb test/models/mixin_network_snapshot_test.rb` and `bin/rails zeitwerk:check`
- [x] T022 Validate scenarios in `specs/007-mixin-api-rate-gate/quickstart.md` (automated checks + manual throttle observation in dev)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — **BLOCKS all user stories**
- **User Stories (Phases 3–6)**: Depend on Phase 2 completion
- **Polish (Phase 7)**: Depends on Phases 3–6 (minimum Phase 3 for MVP deploy)

### User Story Dependencies

| Story | Priority | Depends on | Can parallel with |
| --- | --- | --- | --- |
| US1 | P1 | Phase 2 | — (do first for MVP) |
| US2 | P2 | Phase 2, US1 recommended (QuillBot wrap validates gate in production path) | US3, US4 after US1 |
| US3 | P2 | Phase 2, US1 (uses QuillBot.api) | US2, US4 |
| US4 | P3 | Phase 2 (logging in Gate) | US2, US3 |

### Within Each User Story

- Foundational tests (T006–T007) SHOULD fail before T003–T005 implementation if written first
- Factory wiring (T008, T011–T012) depends on T005
- Story-specific tests depend on story implementation tasks

### Parallel Opportunities

- **Phase 2**: T006 ∥ T007 (after T003–T005, or write tests first against stubs)
- **Phase 4**: T011 ∥ T012 (different files)
- **Cross-story after US1**: US2 (T011–T013) ∥ US3 (T014–T015) ∥ US4 (T016)
- **Polish**: T019 ∥ T020

---

## Parallel Example: User Story 2

```bash
# After Phase 2 checkpoint, launch both factory wires together:
# T011: app/libs/revenue_bot.rb
# T012: app/models/mixin_network_user.rb
# Then T013: gate_test.rb scope isolation
```

---

## Parallel Example: Foundational

```bash
# Implement core (sequential):
# T003 → T004 → T005

# Then tests in parallel:
# T006: test/libs/mixin_api/gate_test.rb
# T007: test/libs/mixin_api/rate_limited_client_test.rb
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T002)
2. Complete Phase 2: Foundational (T003–T007)
3. Complete Phase 3: User Story 1 (T008–T010)
4. **STOP and VALIDATE**: `bin/rails test test/libs/mixin_api/`; confirm `mixin_blaze` survives simulated 429
5. Deploy — fixes production snapshot poll crash

### Incremental Delivery

1. Setup + Foundational → Gate ready
2. US1 → Payment ingestion resilient (**MVP**)
3. US2 → Revenue bot + user wallets gated
4. US3 → Transfer retry verified
5. US4 → Log assertions
6. Polish → OAuth UX + full validation

### Parallel Team Strategy

1. One developer: Phases 1–2 sequentially
2. After checkpoint:
   - Dev A: US1 (T008–T010)
   - Dev B: US2 (T011–T013) — after T008 or in parallel if QuillBot wrap merged
   - Dev C: US3 (T014–T015)
3. US4 + Polish: any developer after their story merges

---

## Notes

- Gate MUST only handle `MixinBot::RateLimitError` (`#throttle?`); never rescue `MixinBot.retryable?` errors centrally
- Blaze WebSocket (`start_blaze_connect`) is out of scope — do not wrap
- `Settings.mixin_api_gate.enabled: false` bypasses all wrapping for emergency disable
- Construct test errors via `MixinBot::RateLimitError.new(code: 429, description: 'Too Many Requests', verb: 'GET', path: '/safe/snapshots')` to match gem shape
- Commit after each phase checkpoint; do not commit secrets in `settings.local.yml`
