# Phase 1 Data Model: Standard OAuth Provider Architecture

No database schema changes. Reuses existing `users`, `user_authorizations`, and `sessions` tables. Introduces runtime-only normalized auth structures and OmniAuth middleware configuration.

## Normalized OAuth Identity (runtime struct)

Provider-agnostic input to the shared sign-in pipeline. Not persisted directly — mapped to `UserAuthorization`.

| Field | Type | Description |
| --- | --- | --- |
| `provider` | Symbol | Maps to `UserAuthorization.provider` enum (`:mixin` first) |
| `uid` | String | Provider-stable user id stored in `UserAuthorization.uid` |
| `access_token` | String, nil | OAuth access token; stored on `UserAuthorization.access_token` |
| `raw` | Hash | Full provider profile payload; stored in `UserAuthorization.raw` JSON |

**Mixin mapping** (from `omniauth-mixin` auth hash):

| Normalized field | Source | Notes |
| --- | --- | --- |
| `provider` | `:mixin` | Fixed |
| `uid` | `auth.extra.raw_info["user_id"]` | MUST match existing rows (UUID); verify strategy output in implementation |
| `access_token` | `auth.credentials.token` | |
| `raw` | `auth.extra.raw_info` | Mixin `/me` `data` object |

**Validation**:
- `provider`, `uid`, `raw` MUST be present before upsert
- `uid` MUST be unique per `provider` (DB constraint already enforces)

## UserAuthorization (existing)

| Attribute | Mixin sign-in behavior |
| --- | --- |
| `provider` | `0` (`mixin`) |
| `uid` | Mixin `user_id` (UUID) |
| `access_token` | Updated each sign-in |
| `raw` | Merged/replaced with latest profile JSON |
| `user_id` | Set on first link if new user created |

**Upsert rule**: `find_or_create_by!(provider:, uid:)` then `update!(access_token:, raw: merged_raw)`.

## User (existing)

Created or updated via `Authenticatable#find_or_create_user_by_auth` logic (moved to `Oauth::SignIn`):

| Scenario | Behavior |
| --- | --- |
| Authorization already linked | Return linked user; if `user.messenger?`, refresh `name` and `biography` from `raw` |
| Authorization unlinked | Create user with `name`, `biography`, `mixin_id` (`identity_number`), `mixin_uuid` (`user_id`), `uid` (`identity_number`); link authorization |

**State**: No AASM changes. `User#messenger?` remains `authorization&.provider == "mixin"`.

## Session (existing)

Created on successful sign-in only.

| Field | Value |
| --- | --- |
| `user_id` | Resolved user |
| `info` | `{ ip:, user_agent: }` from request (unchanged) |
| Cookie | `session[:current_session_id]` = session UUID |

## OAuth Initiation Context (session / OmniAuth params)

Ephemeral; not a DB entity.

| Field | Storage | Purpose |
| --- | --- | --- |
| `return_to` | OmniAuth params or session | Post-login redirect target |
| `state` | OmniAuth-managed | CSRF protection |

**Validation**: `return_to` sanitized via `url_from` before redirect (existing `safe_return_to`).

## Provider Configuration (initializer, not DB)

Per-provider static config registered in OmniAuth builder.

| Provider | Scopes | Credentials source |
| --- | --- | --- |
| `mixin` | `PROFILE:READ` | `credentials[:quill_bot]` |

Future providers add rows to this table in documentation only until implemented.

## Removed / deprecated concepts

| Item | Disposition |
| --- | --- |
| `User.auth_from_mixin(code)` | Remove after `Oauth::SignIn` parity |
| `SessionsController#mixin_auth` | Remove — middleware handles initiation |
| `SessionsController#mixin` | Remove — replaced by callback controller |
| `Settings.mixin_oauth_path` | Deprecate if unused by strategy |
| `COLLECTIBLES:READ` scope | Removed from OAuth requests |

## Entity relationship (unchanged)

```text
User 1──* UserAuthorization (unique provider+uid)
User 1──* Session
```

## Error outcomes (no partial records)

| Error | UserAuthorization | User | Session |
| --- | --- | --- | --- |
| OAuth denied / invalid | No change | No change | Not created |
| Rate limited | No change | No change | Not created |
| Success | Upserted | Found or created | Created |
