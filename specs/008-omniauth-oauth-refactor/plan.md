# Implementation Plan: Standard OAuth Provider Architecture

**Branch**: `008-omniauth-oauth-refactor` | **Date**: 2026-07-05 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/008-omniauth-oauth-refactor/spec.md`  
**Planning constraint**: Drop `COLLECTIBLES:READ` — Mixin OAuth uses `PROFILE:READ` only.

## Summary

Replace Quill's bespoke Mixin OAuth controller flow with **OmniAuth** middleware and the **omniauth-mixin** strategy, routed through a shared **`Oauth::SignIn`** service that upserts `UserAuthorization`, resolves/creates `User`, and establishes the existing cookie session. Twitter account linking stays on the legacy Rack::OAuth2 path for now; the pipeline is designed so the next provider adds a strategy + normalizer branch only.

**Approach**: Add three gems → OmniAuth initializer (`PROFILE:READ` scope) → `Oauth::CallbacksController` → extract sign-in logic from `Authenticatable` → migrate views from GET `link_to` to POST `button_to` → legacy callback redirect → port tests to OmniAuth test mode.

## Technical Context

**Language/Version**: Ruby 4.0.5, Rails 8.1.x  
**Primary Dependencies**: `omniauth`, `omniauth-rails_csrf_protection`, `omniauth-mixin` (github: an-lee/omniauth-mixin); existing `mixin_bot` remains for bot/background API (not OAuth login)  
**Storage**: PostgreSQL — no migration; reuse `users`, `user_authorizations`, `sessions`  
**Testing**: Minitest — `test/services/oauth/`, `test/controllers/oauth/` with `OmniAuth.config.test_mode`  
**Target Platform**: Linux server (Puma); Mixin Messenger in-app webview for login  
**Project Type**: Rails monolith — service objects under `app/services/oauth/`  
**Performance Goals**: Sign-in completes in under 2 seconds excluding Mixin consent UI (SC-003)  
**Constraints**: Preserve `auth_mixin_path` helper and all login entry points; launch-gate skip on OAuth actions; credentials from `credentials[:quill_bot]`; honor Mixin API rate gate if strategy routes through gated client  
**Scale/Scope**: ~3 new gems, 1 initializer, 1 controller, 2 services, route/helper updates, ~15 view call sites (GET→POST), remove 2 controller actions, port existing authenticatable tests

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Reference: `.specify/memory/constitution.md` (Quill v1.0.0)

- [x] **I. Code Quality**: Extends existing patterns — `.call` service objects, concerns slimmed not duplicated; frozen string literal; RuboCop on touched Ruby; credentials stay encrypted
- [x] **II. Testing**: Port `authenticatable_test.rb` scenarios to `Oauth::SignIn`; callback integration tests with OmniAuth mocks; no live Mixin in CI
- [x] **III. UX Consistency**: Reuse connect-wallet modal styling; existing i18n keys (`connected`, `failed_to_connect`, `mixin_rate_limited`); POST buttons match current primary button look
- [x] **IV. Performance**: Login is not a hot batch path; synchronous OAuth acceptable; no benchmark required

> No violations — **Complexity Tracking** table empty.

**Post-design re-check (Phase 1)**: All gates pass. New gems justified by multi-provider goal; service extraction replaces bespoke controller logic rather than adding a parallel stack.

## Project Structure

### Documentation (this feature)

```text
specs/008-omniauth-oauth-refactor/
├── plan.md              # This file
├── research.md          # Phase 0 — gem choice, Rails integration, scope drop
├── data-model.md        # Phase 1 — normalized identity, entity mapping
├── quickstart.md        # Phase 1 — validation guide
├── contracts/
│   └── oauth-pipeline.md
└── tasks.md             # Phase 2 (/speckit-tasks — not yet created)
```

### Source Code (repository root)

```text
Gemfile                                 # omniauth, omniauth-rails_csrf_protection, omniauth-mixin

config/initializers/omniauth.rb         # OmniAuth builder, mixin provider, PROFILE:READ
config/routes.rb                        # callback, failure, legacy redirect, direct :auth_mixin

app/controllers/oauth/
└── callbacks_controller.rb             # create, failure

app/controllers/sessions_controller.rb  # remove mixin_auth, mixin; keep new, delete, twitter_*

app/services/oauth/
├── auth_hash_normalizer.rb             # OmniAuth hash → normalized identity
└── sign_in.rb                          # UserAuthorization + User upsert

app/models/concerns/authenticatable.rb  # remove auth_from_mixin; keep find_or_create_user_by_auth
                                        # (private, called from Oauth::SignIn — or fully inlined)

app/views/sessions/new.html.erb         # link_to → button_to for Mixin
app/views/**                            # other auth_mixin_path callers → POST

test/services/oauth/
├── auth_hash_normalizer_test.rb
└── sign_in_test.rb

test/controllers/oauth/
└── callbacks_controller_test.rb

test/routing/
└── oauth_legacy_callback_test.rb
```

**Structure Decision**: Single-project Rails layout. OAuth lives in `app/services/oauth/` + `app/controllers/oauth/` namespace — mirrors existing service object convention without a new top-level lib.

## Complexity Tracking

> No constitution violations requiring justification.

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| — | — | — |

## Phase 0: Research

Complete — see [research.md](./research.md).

**Key decisions**:

1. **Gems**: `omniauth` + `omniauth-rails_csrf_protection` + `omniauth-mixin` from GitHub.
2. **Scope**: `PROFILE:READ` only — `COLLECTIBLES:READ` dropped (user decision during planning).
3. **Initiation**: POST via `button_to` + CSRF (OmniAuth 2.x); replace GET `link_to` call sites.
4. **Shared pipeline**: `Oauth::AuthHashNormalizer` + `Oauth::SignIn.call` — controller only handles HTTP/session/flash.
5. **Compatibility**: `direct :auth_mixin` helper; `/oauth/mixin/callback` redirect; preserve uid mapping (`UserAuthorization.uid` = Mixin `user_id`).
6. **Twitter**: Out of scope — stays on `SessionsController#twitter_*`.

## Phase 1: Design

Complete — see [data-model.md](./data-model.md), [contracts/oauth-pipeline.md](./contracts/oauth-pipeline.md), [quickstart.md](./quickstart.md).

### Implementation sketch (for `/speckit-tasks`)

**1. Gemfile**

```ruby
gem "omniauth"
gem "omniauth-rails_csrf_protection"
gem "omniauth-mixin", github: "an-lee/omniauth-mixin"
```

**2. Initializer**

```ruby
# config/initializers/omniauth.rb
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :mixin,
           Rails.application.credentials.dig(:quill_bot, :client_id),
           Rails.application.credentials.dig(:quill_bot, :client_secret),
           scope: "PROFILE:READ"
end
```

**3. Routes (essential)**

```ruby
direct :auth_mixin do |options = {}|
  return_to = options[:return_to]
  query = return_to.present? ? "?#{ { return_to: return_to }.to_query }" : ""
  "/auth/mixin#{query}"
end

match "/auth/:provider/callback", to: "oauth/callbacks#create", via: %i[get post]
get "/auth/failure", to: "oauth/callbacks#failure"
get "/oauth/mixin/callback", to: redirect { |params, req|
  "/auth/mixin/callback?#{req.query_string}"
}
# Remove: sessions#mixin_auth, sessions#mixin routes
```

**4. Callback controller (core flow)**

```ruby
def create
  identity = Oauth::AuthHashNormalizer.call(request.env["omniauth.auth"])
  user = Oauth::SignIn.call(identity:, request_info:)
  user_sign_in user.sessions.create!(info: request_info)
  user.notify_for_login
  redirect_to safe_return_to(return_to_param), success: t("connected")
rescue MixinBot::RateLimitError
  redirect_to safe_return_to(return_to_param), alert: t("mixin_rate_limited")
rescue Oauth::SignInError
  redirect_to safe_return_to(return_to_param), alert: t("failed_to_connect")
end
```

**5. View migration pattern**

```erb
<%# Before: link_to auth_mixin_path(...) %>
<%= button_to auth_mixin_path(return_to: ...),
      method: :post,
      data: { turbo: false },
      class: "btn btn-primary ..." do %>
  ...
<% end %>
```

**6. Cleanup**

- Delete `SessionsController#mixin_auth`, `#mixin`
- Remove `skip_before_action :verify_authenticity_token, only: :mixin`
- Remove `User.auth_from_mixin` after test port
- Remove `Settings.mixin_oauth_path` usage if strategy hardcodes Mixin endpoints

### Agent context sync

No `.specify/scripts/bash/update-agent-context.sh` in this repo — skipped (same as specs 002–007).

## Phase 2

Not in scope for `/speckit-plan`. Run **`/speckit-tasks`** next to generate `tasks.md`.

## Spec update (planning input)

Updated [spec.md](./spec.md) FR-008 and Assumptions to reflect `PROFILE:READ`-only scope per user direction during this planning session.
