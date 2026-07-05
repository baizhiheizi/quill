# Phase 1 Contracts: Standard OAuth Provider Architecture

HTTP and internal module contracts for the unified OAuth pipeline. Twitter account linking remains on the legacy `SessionsController` paths until a future migration.

## 1. HTTP routes contract

### Canonical routes (new)

| Method | Path | Handler | Purpose |
| --- | --- | --- | --- |
| `POST` | `/auth/mixin` | OmniAuth middleware | Start Mixin OAuth (CSRF-protected) |
| `GET`, `POST` | `/auth/mixin/callback` | `Oauth::CallbacksController#create` | Complete Mixin OAuth |
| `GET` | `/auth/failure` | `Oauth::CallbacksController#failure` | OmniAuth failure redirect |

### Preserved routes (unchanged behavior)

| Method | Path | Handler | Notes |
| --- | --- | --- | --- |
| `GET` | `/login` | `SessionsController#new` | Modal + Messenger auto-redirect |
| `GET` | `/logout` | `SessionsController#delete` | Sign out |
| `GET` | `/auth/twitter` | `SessionsController#twitter_auth` | Account linking (legacy) |
| `GET` | `/auth/twitter/callback` | `SessionsController#twitter` | Account linking (legacy) |

### Legacy compatibility routes

| Method | Path | Behavior |
| --- | --- | --- |
| `GET` | `/oauth/mixin/callback` | Redirect to `/auth/mixin/callback` preserving query string (301 or internal forward) |

**Invariant**: Legacy callback MUST NOT 404 during transition period (SC-005).

### Route helper contract

`auth_mixin_path(return_to: optional_string)` MUST continue to resolve to `/auth/mixin` with optional `return_to` query param (via `direct :auth_mixin`). Callers MUST use POST to hit this path after migration.

## 2. OmniAuth middleware contract

**File**: `config/initializers/omniauth.rb`

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :mixin, CLIENT_ID, CLIENT_SECRET, scope: "PROFILE:READ"
end
```

**Invariants**:
- Scope MUST be exactly `PROFILE:READ` (no `COLLECTIBLES:READ`)
- Client credentials MUST come from encrypted credentials, not hard-coded
- Provider name symbol MUST be `:mixin` (matches callback URL segment and `UserAuthorization.provider`)

**CSRF**: `omniauth-rails_csrf_protection` MUST be loaded; initiation requests without valid Rails CSRF token MUST be rejected.

## 3. `Oauth::AuthHashNormalizer` contract

**Location**: `app/services/oauth/auth_hash_normalizer.rb` (or `app/libs/oauth/`)

```ruby
Oauth::AuthHashNormalizer.call(omniauth_auth) # => NormalizedOAuthIdentity (struct or Data)
```

**Input**: `OmniAuth::AuthHash` from `request.env["omniauth.auth"]`

**Output fields**: `provider`, `uid`, `access_token`, `raw`

**Mixin branch invariants**:
- `uid` MUST equal Mixin `user_id` from raw profile (same key used by existing `UserAuthorization` rows)
- `raw` MUST contain at minimum: `user_id`, `full_name`, `identity_number` when present in provider response
- MUST raise `Oauth::UnsupportedProviderError` for unknown providers (future-safe)

## 4. `Oauth::SignIn` service contract

**Location**: `app/services/oauth/sign_in.rb`

```ruby
Oauth::SignIn.call(identity:, request_info: nil) # => User
```

**Behavior** (parity with current `Authenticatable#auth_from_mixin` + `find_or_create_user_by_auth`):

1. Upsert `UserAuthorization` on `(provider, uid)`
2. Merge/update `raw` and `access_token`
3. Find linked user OR create new `User` with Mixin field mapping
4. Refresh `name`/`biography` when `user.messenger?` and provider is mixin
5. Return `User` on success

**Errors**:
- Invalid identity (blank uid/raw) → raise `Oauth::SignInError`
- MUST NOT create partial User without authorization or vice versa

**Transaction**: Wrap upsert + user create in `ActiveRecord::Base.transaction` when feasible.

## 5. `Oauth::CallbacksController` contract

**Location**: `app/controllers/oauth/callbacks_controller.rb`

```ruby
class Oauth::CallbacksController < ApplicationController
  skip_before_action :ensure_launched!

  def create  # provider from params[:provider]
  def failure
end
```

### `#create` success path

1. Read `request.env["omniauth.auth"]`
2. Normalize via `Oauth::AuthHashNormalizer`
3. `user = Oauth::SignIn.call(identity:, request_info:)`
4. `user_sign_in user.sessions.create!(info: request_info)`
5. `user.notify_for_login`
6. `redirect_to safe_return_to(return_to_from_omniauth), success: t("connected")`

### `#create` failure path

Rescue expected errors → `redirect_to safe_return_to, alert: appropriate_i18n_key`

| Condition | Flash key |
| --- | --- |
| Rate limit (if detectable) | `mixin_rate_limited` |
| Other sign-in failure | `failed_to_connect` |

### `#failure` (OmniAuth failure rack endpoint)

- Redirect unsigned to `safe_return_to` or `root_path`
- Flash `failed_to_connect`
- MUST NOT create session

### `return_to` resolution order

1. `request.env["omniauth.params"]["return_to"]`
2. `params[:return_to]`
3. `root_path`

All MUST pass through `safe_return_to`.

## 6. View / UX contract

**File**: `app/views/sessions/new.html.erb` and any `auth_mixin_path` caller using GET

- Mixin sign-in control MUST use POST (`button_to` or equivalent) with CSRF token
- Visual styling MUST match current primary button (Mixin logo, rounded-full, full width in modal)
- `return_to` param MUST be forwarded: `auth_mixin_path(return_to: params[:return_to] || request.referer)`
- `from_mixin_messenger?` branch on login page MUST still auto-redirect to Mixin auth (POST redirect or meta refresh — implementation detail in tasks)

**Invariant**: No new user-visible English strings without i18n keys.

## 7. Launch gate contract

`Oauth::CallbacksController` and `SessionsController#new` MUST `skip_before_action :ensure_launched!` (same as today).

## 8. Testing contract

| Test file | Covers |
| --- | --- |
| `test/services/oauth/sign_in_test.rb` | User upsert scenarios (port from `authenticatable_test.rb`) |
| `test/services/oauth/auth_hash_normalizer_test.rb` | Mixin hash mapping |
| `test/controllers/oauth/callbacks_controller_test.rb` | Success, failure, return_to, rate limit |
| `test/routing/oauth_legacy_callback_test.rb` | `/oauth/mixin/callback` compatibility |

**OmniAuth test mode**:
```ruby
OmniAuth.config.test_mode = true
OmniAuth.config.mock_auth[:mixin] = OmniAuth::AuthHash.new(...)
```

MUST NOT call live Mixin OAuth in CI.

## 9. Future provider extension contract

Adding provider `:foo` requires ONLY:

1. OmniAuth builder registration with scopes
2. Normalizer branch for `:foo`
3. Optional UI button
4. `UserAuthorization.provider` enum value if not already present

MUST NOT require changes to `#create` session establishment logic beyond normalizer/sign-in mapping.
