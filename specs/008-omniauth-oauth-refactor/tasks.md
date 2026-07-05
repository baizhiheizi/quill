# Tasks: Standard OAuth Provider Architecture

**Input**: Design documents from `/specs/008-omniauth-oauth-refactor/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/oauth-pipeline.md, quickstart.md

**Tests**: Included per Quill Constitution §II — OAuth sign-in, failure handling, and user upsert are non-trivial behavior with financial/trust impact.

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Maps to spec.md user stories (US1–US5)
- Include exact file paths in descriptions

## Path Conventions

Rails monolith — services in `app/services/oauth/`, controller in `app/controllers/oauth/`, tests in `test/services/oauth/` and `test/controllers/oauth/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Gem dependencies and directory structure

- [x] T001 Add `omniauth`, `omniauth-rails_csrf_protection`, and `omniauth-mixin` (github: an-lee/omniauth-mixin) to `Gemfile`, then run `bundle install`
- [x] T002 Create `app/services/oauth/` and `app/controllers/oauth/` directories

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared OAuth pipeline, middleware, and routes — MUST complete before callback controller or view work

**⚠️ CRITICAL**: No user story implementation until normalizer, sign-in service, initializer, and routes exist

- [x] T003 [P] Add `Oauth::SignInError` and `Oauth::UnsupportedProviderError` in `app/services/oauth/errors.rb`
- [x] T004 [P] Add `Oauth::NormalizedIdentity` struct (provider, uid, access_token, raw) in `app/services/oauth/normalized_identity.rb` per `specs/008-omniauth-oauth-refactor/data-model.md`
- [x] T005 Implement `Oauth::AuthHashNormalizer.call` in `app/services/oauth/auth_hash_normalizer.rb` with Mixin branch mapping `uid` to `extra.raw_info["user_id"]` and raising `Oauth::UnsupportedProviderError` for unknown providers
- [x] T006 Implement `Oauth::SignIn.call` in `app/services/oauth/sign_in.rb` by extracting upsert + user-resolution logic from `app/models/concerns/authenticatable.rb` (`find_or_create_user_by_auth` behavior, messenger name/biography refresh)
- [x] T007 Add `config/initializers/omniauth.rb` registering `:mixin` provider with `credentials[:quill_bot]` and scope `"PROFILE:READ"` only (no `COLLECTIBLES:READ`) per `contracts/oauth-pipeline.md` §2
- [x] T008 Update `config/routes.rb`: add `direct :auth_mixin`, `match "/auth/:provider/callback"` → `oauth/callbacks#create`, `get "/auth/failure"` → `oauth/callbacks#failure`, legacy `get "/oauth/mixin/callback"` redirect preserving query string; remove `sessions#mixin_auth` and `sessions#mixin` routes
- [x] T009 [P] Create `test/services/oauth/auth_hash_normalizer_test.rb` covering Mixin hash mapping and unknown-provider error (OmniAuth test hash fixtures, no network)
- [x] T010 [P] Create `test/services/oauth/sign_in_test.rb` porting scenarios from `test/models/concerns/authenticatable_test.rb` (new user, existing user reuse, messenger profile refresh, invalid identity)

**Checkpoint**: `bin/rails test test/services/oauth/` passes; routes resolve; OmniAuth middleware loads

---

## Phase 3: User Story 1 — Sign In with Mixin (Priority: P1) 🎯 MVP

**Goal**: Users sign in via Mixin from connect-wallet modal, Messenger webview, and `return_to` flows with parity to pre-refactor behavior

**Independent Test**: POST to `/auth/mixin` from modal → mock callback → signed-in session, `connected` flash, correct user/authorization rows, safe `return_to` redirect

### Tests for User Story 1

- [x] T011 [P] [US1] Create `test/controllers/oauth/callbacks_controller_test.rb` with OmniAuth test mode success scenarios: new user creation, existing user reuse, `return_to` internal path, session `info` metadata (ip, user_agent), and `notify_for_login` invoked

### Implementation for User Story 1

- [x] T012 [US1] Implement `Oauth::CallbacksController` in `app/controllers/oauth/callbacks_controller.rb` with `#create` success path: normalize auth hash → `Oauth::SignIn.call` → `user_sign_in` + session create → `notify_for_login` → redirect with `t("connected")`; `skip_before_action :ensure_launched!`
- [x] T013 [US1] Migrate Mixin sign-in control in `app/views/sessions/new.html.erb` from GET `link_to auth_mixin_path` to POST `button_to auth_mixin_path` with `data: { turbo: false }`, preserving styling and `return_to: params[:return_to] || request.referer`
- [x] T014 [US1] Update `app/controllers/sessions_controller.rb` `#new` Messenger auto-initiation (`from_mixin_messenger?`) to use POST-compatible flow (e.g., render auto-submitting form or `button_to` page) instead of GET redirect to `auth_mixin_path`
- [x] T015 [US1] Update standalone connect-wallet button in `app/views/sessions/new.html.erb` (non-modal branch, line ~29) from GET `link_to` to POST `button_to auth_mixin_path`
- [x] T016 [US1] Remove `SessionsController#mixin_auth` and `#mixin` actions and their private dependencies from `app/controllers/sessions_controller.rb`

**Checkpoint**: Manual quickstart Story 1 (modal + Messenger + return_to) passes; US1 controller tests green

---

## Phase 4: User Story 2 — OAuth Failures Handled Gracefully (Priority: P1)

**Goal**: Denied auth, invalid callbacks, rate limits, and API errors produce safe redirects with i18n flash messages and no partial sessions

**Independent Test**: OmniAuth failure route and simulated errors → unsigned user, appropriate flash (`failed_to_connect` or `mixin_rate_limited`), no new `Session` row

### Tests for User Story 2

- [x] T017 [P] [US2] Extend `test/controllers/oauth/callbacks_controller_test.rb` with failure scenarios: `#failure` action (denied auth), invalid/missing auth hash, `MixinBot::RateLimitError` rescue → `mixin_rate_limited`, generic sign-in error → `failed_to_connect`, `return_to` preserved on failure

### Implementation for User Story 2

- [x] T018 [US2] Implement `#failure` in `app/controllers/oauth/callbacks_controller.rb` redirecting unsigned to `safe_return_to` with `t("failed_to_connect")`
- [x] T019 [US2] Add error handling in `#create`: rescue `MixinBot::RateLimitError` → `mixin_rate_limited` flash; rescue `Oauth::SignInError` / invalid auth → `failed_to_connect`; no session created on any failure path
- [x] T020 [US2] Implement `return_to` resolution from `request.env["omniauth.params"]["return_to"]` and `params[:return_to]` through `safe_return_to` in `app/controllers/oauth/callbacks_controller.rb`

**Checkpoint**: All OAuth failure paths tested; no 500 errors in failure scenarios (SC-003)

---

## Phase 5: User Story 3 — Platform Ready for Additional OAuth Providers (Priority: P2)

**Goal**: Next provider adds strategy + normalizer branch only; shared callback and sign-in pipeline unchanged

**Independent Test**: Stub `:test_provider` auth hash through normalizer + `Oauth::SignIn` without modifying `Oauth::CallbacksController#create` session logic

### Tests for User Story 3

- [x] T021 [P] [US3] Add stub-provider normalizer branch test in `test/services/oauth/auth_hash_normalizer_test.rb` proving a second provider maps to `NormalizedIdentity` without Mixin-specific logic in `app/services/oauth/sign_in.rb`

### Implementation for User Story 3

- [x] T022 [US3] Refactor `app/services/oauth/auth_hash_normalizer.rb` to use provider-keyed adapter map (e.g., `PROVIDERS = { mixin: MixinAdapter, ... }`) so new providers register one adapter class, not inline conditionals in the controller
- [x] T023 [US3] Ensure `Oauth::SignIn` in `app/services/oauth/sign_in.rb` accepts any `NormalizedIdentity` provider symbol mappable to `UserAuthorization.provider` enum — no hard-coded Mixin scope strings or Mixin-only branches outside user-field mapping

**Checkpoint**: Architecture review confirms adding a provider requires initializer registration + adapter only (SC-004)

---

## Phase 6: User Story 4 — Existing Accounts and Sessions Remain Valid (Priority: P2)

**Goal**: Existing `UserAuthorization` rows and active sessions work through migration; legacy callback URL continues to function

**Independent Test**: Sign-in with fixture user having existing Mixin authorization → same `User.id`, one authorization row updated; `GET /oauth/mixin/callback?code=...` reaches canonical handler

### Tests for User Story 4

- [x] T024 [P] [US4] Create `test/routing/oauth_legacy_callback_test.rb` asserting `GET /oauth/mixin/callback` redirects to `/auth/mixin/callback` with query string preserved
- [x] T025 [P] [US4] Add `test/services/oauth/sign_in_test.rb` scenario: existing `UserAuthorization` keyed on `(provider: mixin, uid: user_id)` updates token/raw without duplicate row or duplicate `User`

### Implementation for User Story 4

- [x] T026 [US4] Remove `User.auth_from_mixin` from `app/models/concerns/authenticatable.rb`; keep or inline `find_or_create_user_by_auth` only if still needed by `Oauth::SignIn` (no duplicate code paths)
- [x] T027 [US4] Remove or redirect `test/models/concerns/authenticatable_test.rb` — delete if fully superseded by `test/services/oauth/sign_in_test.rb`, or reduce to any remaining concern methods

**Checkpoint**: Zero duplicate users for same Mixin identity in tests (SC-002); legacy callback route green

---

## Phase 7: User Story 5 — Security and Session Integrity (Priority: P2)

**Goal**: OAuth CSRF state validation, POST initiation with Rails CSRF, safe redirects, launch-gate exemption

**Independent Test**: POST without CSRF token rejected; external `return_to` sanitized; OAuth state validated by OmniAuth (invalid state → failure path)

### Tests for User Story 5

- [x] T028 [P] [US5] Extend `test/controllers/oauth/callbacks_controller_test.rb` with security cases: external `return_to` URL falls back to root; successful callback records request metadata on `Session#info`

### Implementation for User Story 5

- [x] T029 [US5] Verify `omniauth-rails_csrf_protection` is required in Gemfile and loaded; confirm initiation via POST `button_to` includes authenticity token in `app/views/sessions/new.html.erb`
- [x] T030 [US5] Remove obsolete `skip_before_action :verify_authenticity_token, only: :mixin` from `app/controllers/sessions_controller.rb` (action deleted in T016)
- [x] T031 [US5] Confirm `Oauth::CallbacksController` has `skip_before_action :ensure_launched!` only (not CSRF skip on initiation — handled by POST + gem)

**Checkpoint**: No open-redirect regressions; launch gate still bypassed for login/OAuth only

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Cleanup, lint, full suite, deploy readiness

- [x] T032 [P] Remove unused `Settings.mixin_oauth_path` reference from `app/controllers/sessions_controller.rb` and deprecate key in `config/settings.yml` if no other callers remain
- [x] T033 Run `bin/rubocop` on `app/services/oauth/`, `app/controllers/oauth/`, `config/initializers/omniauth.rb`, and touched test files
- [x] T034 Run `bin/rails test test/services/oauth/ test/controllers/oauth/ test/routing/oauth_legacy_callback_test.rb` and `bin/rails zeitwerk:check`
- [x] T035 Validate against `specs/008-omniauth-oauth-refactor/quickstart.md` (manual Story 1–2 + scope check: Mixin consent shows `PROFILE:READ` only)
- [x] T036 Register canonical callback URL `https://quill.im/auth/mixin/callback` in Mixin Developer Dashboard (deploy checklist — document in PR description)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — **BLOCKS all user stories**
- **US1 (Phase 3)**: Depends on Phase 2 — **MVP**
- **US2 (Phase 4)**: Depends on T012 (callback controller exists); can overlap with US1 polish
- **US3 (Phase 5)**: Depends on T005, T006 (normalizer + sign-in); can run after Phase 2
- **US4 (Phase 6)**: Depends on T010, T012 (sign-in tests + callback); cleanup after US1 proven
- **US5 (Phase 7)**: Depends on T012–T016 (controller + views migrated to POST)
- **Polish (Phase 8)**: Depends on US1–US5 desired for release

### User Story Dependencies

| Story | Depends on | Can start after |
| --- | --- | --- |
| US1 (P1) | Phase 2 | T010 passes |
| US2 (P1) | US1 callback controller (T012) | T012 |
| US3 (P2) | Phase 2 services | T005, T006 |
| US4 (P2) | US1 sign-in parity | T010, T012 |
| US5 (P2) | US1 view POST migration | T013–T016 |

### Within Each User Story

- Tests written first (fail before implementation)
- Services before controller
- Controller before view migration
- Legacy cleanup (US4) after new path verified

### Parallel Opportunities

**Phase 2** (after T001–T002):
```bash
# Parallel: error classes + struct + tests
T003, T004, T009, T010
# Then sequential: T005 → T006 → T007 → T008
```

**Phase 3** (after Phase 2):
```bash
# Parallel: write controller tests while implementing views
T011 ∥ T013, T015
```

**Phase 4–7** (after US1 checkpoint):
```bash
# US3 adapter refactor can run parallel to US2 failure tests
T021, T022 ∥ T017, T018
```

---

## Parallel Example: User Story 1

```bash
# Tests first (should fail):
T011 — test/controllers/oauth/callbacks_controller_test.rb

# Then parallel implementation:
T013 — app/views/sessions/new.html.erb (modal button)
T015 — app/views/sessions/new.html.erb (standalone button)
# Sequential:
T012 — app/controllers/oauth/callbacks_controller.rb
T014 — app/controllers/sessions_controller.rb (Messenger POST)
T016 — remove old mixin actions
```

---

## Implementation Strategy

### MVP First (User Story 1 + 2)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (**critical**)
3. Complete Phase 3: US1 — Mixin sign-in works end-to-end
4. Complete Phase 4: US2 — Failures handled gracefully
5. **STOP and VALIDATE**: Run quickstart Stories 1–2; deploy to staging

### Incremental Delivery

1. Setup + Foundational → pipeline ready
2. US1 + US2 → **MVP deploy** (all login paths work, failures safe)
3. US3 → extensibility proven for next provider
4. US4 → old code removed, legacy URLs confirmed
5. US5 → security hardening verified
6. Polish → lint, full suite, Mixin dashboard callback URL

### Parallel Team Strategy

With two developers after Phase 2:

- **Developer A**: US1 controller + tests (T011–T012, T016)
- **Developer B**: View POST migration (T013–T015)
- Merge → US2 together → US4 cleanup

---

## Notes

- Mixin OAuth scope is **`PROFILE:READ` only** — do not request `COLLECTIBLES:READ` (planning decision)
- Twitter linking (`SessionsController#twitter_auth`, `#twitter`) is **out of scope** — do not migrate
- `auth_mixin_path` is only used in `app/views/sessions/new.html.erb` and `SessionsController#new` today — grep before marking view tasks complete
- Use `OmniAuth.config.test_mode = true` in tests; no live Mixin OAuth in CI
- Commit after each phase checkpoint

---

## Task Summary

| Phase | Tasks | Story |
| --- | --- | --- |
| Phase 1: Setup | T001–T002 | — |
| Phase 2: Foundational | T003–T010 | — |
| Phase 3: US1 Sign In | T011–T016 | US1 |
| Phase 4: US2 Failures | T017–T020 | US2 |
| Phase 5: US3 Extensibility | T021–T023 | US3 |
| Phase 6: US4 Continuity | T024–T027 | US4 |
| Phase 7: US5 Security | T028–T031 | US5 |
| Phase 8: Polish | T032–T036 | — |
| **Total** | **36 tasks** | |

**MVP scope**: Phase 1 + Phase 2 + Phase 3 + Phase 4 (T001–T020) — Mixin sign-in and failure handling.

**Format validation**: All 36 tasks use `- [x]`, sequential ID (T001–T036), story labels on US phases, and explicit file paths.
