# Quickstart: Validating Standard OAuth Provider Architecture

Manual and automated validation for the OmniAuth Mixin migration. See [data-model.md](./data-model.md) and [contracts/oauth-pipeline.md](./contracts/oauth-pipeline.md) for field mappings and route contracts.

## Prerequisites

```bash
bundle install
bin/rails db:prepare
```

Ensure Mixin bot OAuth credentials are configured:

- `EDITOR=vim bin/rails credentials:edit --development` — `quill_bot.client_id`, `quill_bot.client_secret`
- `config/settings.local.yml` with correct `host` for local callbacks (e.g. `http://localhost:3000`)

Register callback URL in Mixin Developer Dashboard:

- Development: `http://localhost:3000/auth/mixin/callback`
- Staging/production: `https://quill.im/auth/mixin/callback`

## Automated checks (run after implementation)

```bash
bin/rubocop app/controllers/oauth/ app/services/oauth/ config/initializers/omniauth.rb
bin/rails test test/services/oauth/ test/controllers/oauth/
bin/rails test test/models/concerns/authenticatable_test.rb  # removed or redirected to sign_in tests
bin/rails zeitwerk:check
```

All OAuth tests MUST pass without network access (OmniAuth test mode).

## Unit validation — sign-in pipeline

```bash
bin/rails test test/services/oauth/sign_in_test.rb -v
bin/rails test test/services/oauth/auth_hash_normalizer_test.rb -v
```

Expected scenarios (parity with pre-refactor `auth_from_mixin`):

- New Mixin user → new `User` + `UserAuthorization`
- Existing authorization → same user, updated token/raw
- Messenger user repeat login → refreshed name/biography
- Invalid profile → error, no records created

## Integration validation — callback controller

```bash
bin/rails test test/controllers/oauth/callbacks_controller_test.rb -v
```

Expected:

- Mock Mixin auth hash → signed-in session, `connected` flash
- OmniAuth failure → unsigned, `failed_to_connect` flash
- `return_to` internal path honored; external URL rejected
- Rate-limit error → `mixin_rate_limited` flash (when simulated)

## Legacy callback route

```bash
bin/rails test test/routing/oauth_legacy_callback_test.rb -v
```

Expected: `GET /oauth/mixin/callback?code=...&state=...` reaches the same handler as `/auth/mixin/callback`.

## Story 1 — Sign in with Mixin (P1, manual)

1. Start `bin/dev`, open `http://localhost:3000`
2. Click **Connect Wallet** in masthead → modal opens
3. Click **Mixin Messenger** (POST) → redirect to Mixin OAuth
4. Approve with a test Mixin account
5. Return to Quill signed in; navbar shows profile

**Messenger webview**: Open Quill inside Mixin Messenger (or simulate UA containing `Mixin`) → visit `/login` → should initiate OAuth without modal.

**return_to**: From a gated article, click login → after auth, land back on the article page.

## Story 2 — OAuth failures (P1, manual)

1. Start OAuth, deny at Mixin consent → unsigned, error flash, no crash
2. In test mode or stub, simulate rate limit → `mixin_rate_limited` message

## Story 3 — Existing user continuity (P2, manual)

1. Note user id in console: `User.find_by(mixin_id: "...").id`
2. Sign out, sign in again via Mixin
3. Confirm same user id; `UserAuthorization` row updated, not duplicated

```ruby
UserAuthorization.mixin.where(uid: "<mixin_user_uuid>").count # => 1
```

## Story 4 — Scope reduction (planning constraint)

On Mixin consent screen, confirm requested permission is profile read only — **no collectibles scope**.

Existing users re-authenticating should still sign in successfully with reduced scope.

## Story 5 — Extensibility smoke check (P2, post-implementation review)

Verify in code review:

- `Oauth::CallbacksController#create` has no Mixin-specific uid/session logic inline
- New provider needs normalizer branch + OmniAuth registration only (per contract §9)

Optional: add `test/services/oauth/sign_in_stub_provider_test.rb` with a fake `:test_provider` normalizer branch.

## Rollback checklist

If production sign-in fails after deploy:

1. Confirm Mixin app callback URL includes `/auth/mixin/callback`
2. Confirm legacy `/oauth/mixin/callback` redirect is active
3. Check logs for OmniAuth CSRF failures (usually missing POST on initiation)
4. Emergency: revert deploy; old flow remains in git history until fully removed

## Out of scope for this quickstart

- Twitter account linking (`/auth/twitter`) — unchanged
- API `AccessToken` authentication
- Admin login
