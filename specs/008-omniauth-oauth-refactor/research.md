# Phase 0 Research: Standard OAuth Provider Architecture

**Date**: 2026-07-05  
**Scope note**: Mixin OAuth scope reduced to `PROFILE:READ` only — `COLLECTIBLES:READ` dropped per product decision during `/speckit-plan`.

## 1. Current implementation audit

| Concern | Today | Location |
| --- | --- | --- |
| OAuth initiation | Manual redirect URL built from `Settings.mixin_oauth_path`, `QuillBot.api.client_id`, hard-coded scopes | `SessionsController#mixin_auth` |
| Callback | Manual `params[:code]` exchange via `User.auth_from_mixin` | `SessionsController#mixin` |
| User upsert | `Authenticatable#auth_from_mixin` → `UserAuthorization` + `User` | `app/models/concerns/authenticatable.rb` |
| Session creation | `user.sessions.create!` + `user_sign_in` + `notify_for_login` | `SessionsController#mixin` |
| CSRF | `skip_before_action :verify_authenticity_token, only: :mixin` | `SessionsController` |
| State / CSRF for OAuth | None (custom flow) | — |
| Rate limits | Rescue `MixinBot::RateLimitError` → flash | `SessionsController#mixin` |
| Callback URLs | `/auth/mixin/callback`, `/oauth/mixin/callback` (duplicate) | `config/routes.rb` |
| Twitter linking | Separate Rack::OAuth2 flow | `SessionsController#twitter_auth`, `#twitter` |

**Uid mapping (must preserve)**:
- `UserAuthorization.uid` = Mixin `user_id` (UUID string from `/me`)
- `User.uid` = Mixin `identity_number` (numeric string) for mixin users
- `User.mixin_uuid` = Mixin `user_id`

## 2. Gem selection

### Decision: `omniauth` + `omniauth-rails_csrf_protection` + `omniauth-mixin`

**Rationale**:
- User-specified stack; `omniauth-mixin` (an-lee/omniauth-mixin) implements OAuth2 token exchange and `/me` profile fetch, producing a standard OmniAuth auth hash.
- `omniauth-rails_csrf_protection` integrates OmniAuth 2.x POST-only request phase with Rails CSRF tokens — preferred over permanently allowing unauthenticated GET initiation.
- Reuses industry-standard middleware instead of maintaining manual URL construction and code exchange in the controller.

**Alternatives considered**:

| Alternative | Rejected because |
| --- | --- |
| Keep bespoke flow, only extract service object | Does not satisfy "standard OAuth" goal; each new provider duplicates initiation/callback/state |
| `devise` + `omniauth-*` | Quill has no Devise; session model is custom (`Session` UUID in cookie) — Devise would be a large parallel auth stack |
| Continue `mixin_bot` OAuth helpers inside controller | Already works but couples login to bot API client; OmniAuth strategy isolates OAuth from background bot traffic |

**Gemfile additions** (implementation phase):
```ruby
gem "omniauth"
gem "omniauth-rails_csrf_protection"
gem "omniauth-mixin", github: "an-lee/omniauth-mixin"
```

Credentials: reuse `Rails.application.credentials[:quill_bot]` (`client_id`, `client_secret`) already consumed by `QuillBot.build_api`.

## 3. OmniAuth + Rails 8 integration pattern

### Decision: Rack middleware + dedicated callback controller + shared sign-in service

**Middleware** (`config/initializers/omniauth.rb`):
```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :mixin,
           Rails.application.credentials.dig(:quill_bot, :client_id),
           Rails.application.credentials.dig(:quill_bot, :client_secret),
           scope: "PROFILE:READ"
end
```

**Routes**:
- Initiation: `POST /auth/mixin` (OmniAuth middleware; CSRF-protected via `omniauth-rails_csrf_protection`)
- Callback: `GET|POST /auth/mixin/callback` → `Oauth::CallbacksController#create`
- Legacy: `GET /oauth/mixin/callback` → 301/302 to `/auth/mixin/callback` with query string preserved
- Failure: `GET /auth/failure` → `Oauth::CallbacksController#failure`

**Initiation UX migration**: Current views use `link_to auth_mixin_path` (GET). OmniAuth 2.x prefers POST.

**Decision**: Replace login `link_to` with `button_to` (POST) styled as existing primary buttons, preserving visual design. Allow GET only if a specific entry point cannot POST (evaluate Mixin Messenger webview — if POST works, no GET exception needed).

**`return_to` preservation**: Store in OmniAuth `origin` or session before redirect:
- Pass `return_to` as query param on POST `/auth/mixin`
- Read from `request.env["omniauth.params"]["return_to"]` or `request.env["omniauth.origin"]` on callback
- Continue using `ApplicationController#safe_return_to` for final redirect

## 4. Shared post-authentication pipeline

### Decision: `Oauth::SignIn` service object (`.call`)

Extract logic from `Authenticatable#auth_from_mixin` into provider-agnostic flow:

```
AuthHash (normalized) → upsert UserAuthorization → find_or_create User → return User
```

Controller callback responsibility only:
1. Normalize `request.env["omniauth.auth"]` to internal struct
2. Call `Oauth::SignIn.call(...)`
3. Create `Session`, `user_sign_in`, `notify_for_login`, redirect with flash

**Rationale**: Matches Quill `.call` service convention; Twitter can migrate later by producing the same normalized struct.

**Mixin-specific mapping** from `omniauth-mixin` hash:
- `provider` → `:mixin`
- `uid` → `extra.raw_info["user_id"]` (NOT top-level uid if strategy uses identity_number — verify in implementation; MUST match existing `UserAuthorization` rows keyed on `user_id`)
- `access_token` → `credentials.token`
- `raw` → `extra.raw_info` (full Mixin `/me` payload)

Deprecate `User.auth_from_mixin(code)` — remove after migration; tests move to `Oauth::SignIn` + callback integration tests.

## 5. Error handling

| Failure mode | Handler |
| --- | --- |
| User denies at Mixin | OmniAuth failure route → flash `failed_to_connect`, redirect `safe_return_to` |
| Invalid/missing auth hash | Same as deny |
| `MixinBot::RateLimitError` during token/profile fetch | Strategy may bubble as OAuth failure; map in `Oauth::CallbacksController#failure` when error class detectable, else generic failure message; prefer rescuing in custom strategy wrapper only if gem exposes hook — otherwise failure message + log |
| Other Mixin API errors | `failed_to_connect` flash, no session |

**Note**: Once OAuth runs through OmniAuth strategy (not `QuillBot.interactive_api` directly), rate-limit rescue moves to failure handler. If strategy uses raw HTTP without `MixinApi` gate, consider wrapping strategy HTTP client OR rescuing at callback — detail for tasks phase.

## 6. Route and helper compatibility

### Decision: `direct :auth_mixin` route helper

Preserve `auth_mixin_path(return_to: ...)` call sites (~15 views) without changing every caller signature:

```ruby
direct :auth_mixin do |options = {}|
  return_to = options[:return_to]
  query = return_to.present? ? "?#{ { return_to: return_to }.to_query }" : ""
  "/auth/mixin#{query}"
end
```

Views change from `link_to ... auth_mixin_path` to `button_to ... auth_mixin_path, method: :post` (or `form_with` + `data-turbo=false` if cross-host redirect issues arise).

Remove `SessionsController#mixin_auth` and `#mixin` actions.

## 7. Security improvements

| Item | Action |
| --- | --- |
| OAuth CSRF (state) | Provided by OmniAuth + `omniauth-rails_csrf_protection` |
| Rails CSRF on initiation | POST + authenticity token via `button_to` |
| Callback CSRF skip | Remove blanket `skip_before_action :verify_authenticity_token` for mixin; OmniAuth callback may still need skip for GET callback — use gem defaults |
| Open redirect | Keep `safe_return_to` / `url_from` validation |

## 8. Multi-provider extensibility

Future provider checklist (not implemented now):
1. Add gem strategy or configure generic OAuth2 strategy
2. Register in OmniAuth builder with provider-specific scopes
3. Add normalizer branch in `Oauth::AuthHashNormalizer` (or per-provider adapter class)
4. Add `button_to` in UI when product requests
5. Map to existing `UserAuthorization.provider` enum value

Twitter linking remains on `SessionsController#twitter_*` until a follow-up spec.

## 9. Testing strategy

| Layer | Approach |
| --- | --- |
| `Oauth::SignIn` | Unit tests mirroring `authenticatable_test.rb` scenarios (new user, existing user, profile refresh, error paths) |
| `Oauth::CallbacksController` | Integration tests with OmniAuth test mode (`OmniAuth.config.test_mode = true`) and mock auth hash |
| Legacy callback route | Routing test: `/oauth/mixin/callback` forwards to canonical handler |
| Rate limit | Stub strategy failure or simulate `OmniAuth::Strategies::OAuth2` error mapping |

No live Mixin OAuth calls in CI.

## 10. Configuration / deploy checklist

- Register canonical callback URL in Mixin Developer Dashboard: `https://quill.im/auth/mixin/callback`
- Keep legacy `/oauth/mixin/callback` redirect for one release cycle (FR-011)
- Scope change to `PROFILE:READ` only — update Mixin app consent screen (users may see reduced permissions on re-auth)
- `Settings.mixin_oauth_path` may become unused (strategy embeds endpoints) — remove in cleanup task if redundant
