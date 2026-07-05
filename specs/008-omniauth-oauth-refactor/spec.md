# Feature Specification: Standard OAuth Provider Architecture

**Feature Branch**: `008-omniauth-oauth-refactor` (not yet created — no branch-creation hook is configured in this workspace; create manually before implementing if desired)

**Created**: 2026-07-05

**Status**: Draft

**Input**: User description: "Refactor the Mixin OAuth flow to standard OAuth flow using omniauth with omniauth-mixin. We'll add more OAuth providers later. Design it well."

*(Quill today implements Mixin sign-in with a bespoke controller flow: a custom redirect to the Mixin authorization page, a manual code exchange via `User.auth_from_mixin`, and separate callback routes. Twitter account linking uses another one-off OAuth implementation. This works but duplicates OAuth concerns (state, callback handling, token exchange, provider metadata) and makes each new provider a bespoke integration. This spec defines a unified, standards-based OAuth architecture with Mixin as the first migrated provider, preserving all current login behavior while making future providers a configuration and strategy addition rather than a rewrite.)*

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sign In with Mixin (Priority: P1)

As a reader or author, I can sign in to Quill with my Mixin Messenger account using the same entry points and post-login experience as today — whether I open Quill in a desktop browser, mobile browser, or the Mixin Messenger in-app webview.

**Why this priority**: Mixin is Quill's primary and only login method for platform access. Any regression blocks all authenticated use (publishing, purchasing, payouts).

**Independent Test**: Start from the connect-wallet modal or direct Mixin Messenger link, complete Mixin authorization, and land signed in on the intended page with profile data populated — without creating duplicate accounts for returning users.

**Acceptance Scenarios**:

1. **Given** an unsigned visitor on the public site, **When** they choose "Mixin Messenger" from the connect-wallet modal, **Then** they are redirected to Mixin's authorization page and, after approving, return to Quill signed in.
2. **Given** a visitor in the Mixin Messenger in-app browser, **When** they visit the login page, **Then** they are sent directly to Mixin authorization (no modal step) and return signed in on success.
3. **Given** a signed-in flow initiated with a `return_to` destination, **When** authorization succeeds, **Then** the user lands on that safe internal destination (or the home page if invalid).
4. **Given** an existing user who previously signed in via Mixin, **When** they sign in again, **Then** the same Quill account is reused (matched by Mixin identity), name and biography are refreshed from the provider, and no duplicate user row is created.
5. **Given** a first-time Mixin user, **When** authorization succeeds, **Then** a new Quill user is created with Mixin profile fields (display name, biography, Mixin ID, Mixin UUID) and a linked authorization record.

---

### User Story 2 - OAuth Failures Are Handled Gracefully (Priority: P1)

As a user attempting to sign in, when authorization fails, is denied, or the identity provider is temporarily unavailable, I receive a clear outcome and am not left in a broken or ambiguous state.

**Why this priority**: OAuth failures are common (user cancels, rate limits, network errors). Poor handling erodes trust and generates support load.

**Independent Test**: Simulate denied authorization, invalid callback parameters, provider rate limiting, and provider API errors; verify each produces a safe redirect with an appropriate user-visible message and no partial session created.

**Acceptance Scenarios**:

1. **Given** a user who denies authorization at Mixin, **When** the callback is received, **Then** they are redirected back to Quill unsigned with a failure message — not signed in with a half-created account.
2. **Given** the Mixin identity service is rate-limiting token or profile requests, **When** sign-in is attempted during the limit, **Then** the user sees a rate-limit message and can retry later — the request does not crash the application.
3. **Given** a callback with missing or invalid authorization data, **When** the platform processes it, **Then** the user is redirected safely without a new session and without exposing internal error details.
4. **Given** a failed sign-in attempt, **When** the user is redirected, **Then** the `return_to` destination (if provided and safe) is preserved for a subsequent retry.

---

### User Story 3 - Platform Ready for Additional OAuth Providers (Priority: P2)

As the product team, we can add a new OAuth-based sign-in or account-linking provider by implementing a provider-specific strategy and configuration — without copying and maintaining a separate controller action, callback route pattern, and token-exchange block for each provider.

**Why this priority**: The explicit goal is extensibility. The Mixin migration must establish patterns (callback routing, auth hash normalization, authorization persistence, session creation) that the next provider reuses.

**Independent Test**: Review the architecture against a hypothetical second provider (e.g., a generic OpenID Connect provider): confirm that only provider-specific configuration and a strategy adapter are needed; core sign-in/session logic is shared.

**Acceptance Scenarios**:

1. **Given** the unified OAuth architecture is in place, **When** a new provider strategy is registered, **Then** it uses the same callback entry point and shared post-authentication pipeline as Mixin.
2. **Given** multiple providers are configured, **When** a user completes authorization for one provider, **Then** the resulting authorization is stored with a distinct provider identifier and does not collide with other providers' records for the same person.
3. **Given** provider-specific OAuth scopes, **When** a provider is configured, **Then** scopes are declared per provider without hard-coding Mixin scope strings into shared logic.
4. **Given** the shared pipeline, **When** any provider returns a normalized identity payload, **Then** the platform can upsert a `UserAuthorization` and resolve or create the corresponding `User` through one code path.

---

### User Story 4 - Existing Accounts and Sessions Remain Valid (Priority: P2)

As an existing Quill user, my account, linked Mixin authorization, and active session continue to work through and after the OAuth refactor — I am not forced to re-register or lose access.

**Why this priority**: The refactor replaces infrastructure, not the user base. Data continuity is required for a safe rollout.

**Independent Test**: Sign in with a fixture user that already has a Mixin `UserAuthorization` before deploy; after deploy, sign in again via the new flow and confirm the same user ID, authorization row (updated token/profile), and expected session behavior.

**Acceptance Scenarios**:

1. **Given** existing `UserAuthorization` rows keyed by `(provider: mixin, uid)`, **When** the user signs in via the new flow, **Then** the existing authorization row is updated (access token, raw profile) rather than duplicated.
2. **Given** a user with an active session created before the refactor, **When** they continue browsing without re-authenticating, **Then** their session remains valid until expiry or sign-out.
3. **Given** legacy callback URLs still in use (bookmarks, Mixin app configuration), **When** a callback hits a deprecated path, **Then** authorization still completes successfully or the user is redirected to the canonical callback without error.

---

### User Story 5 - Security and Session Integrity (Priority: P2)

As the platform, OAuth sign-in must resist cross-site request forgery and open redirects so users cannot be tricked into signing in to the wrong account or sent to malicious external URLs after login.

**Why this priority**: OAuth callbacks are a common attack surface. The current flow skips CSRF verification on the Mixin callback; the new architecture must enforce standard protections.

**Independent Test**: Attempt callback replay without valid state, tampered `return_to` values pointing off-site, and CSRF on the initiation path; verify all are rejected or sanitized.

**Acceptance Scenarios**:

1. **Given** an OAuth initiation request, **When** the user is sent to the provider, **Then** a cryptographically unpredictable state value is stored and validated on callback.
2. **Given** a `return_to` parameter containing an external URL, **When** sign-in completes, **Then** the user is redirected only to an allowed on-site path.
3. **Given** a successful callback, **When** a session is created, **Then** request metadata (IP, user agent) is recorded on the session as today for audit purposes.
4. **Given** a sign-in notification is configured for new device or location login, **When** authorization succeeds, **Then** the existing login notification behavior is preserved.

---

### Edge Cases

- User starts OAuth in one browser tab and completes in another — state validation fails safely with a retry path.
- Mixin returns a profile without optional fields (e.g., missing biography or identity number) — user creation still succeeds with sensible defaults.
- Concurrent sign-in attempts for the same Mixin identity from two devices — both resolve to the same user; authorization token reflects the latest successful exchange.
- Provider callback arrives twice (double submit or refresh) — idempotent handling; user ends signed in once without duplicate sessions causing errors.
- Platform is behind the launch gate — sign-in remains accessible even when other pages redirect to landing (current `ensure_launched!` skip on session actions must be preserved).
- Operator rotates Mixin OAuth client credentials — sign-in continues after configuration update without code changes beyond credentials/settings.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The platform MUST route Mixin sign-in through a standard OAuth middleware pattern (initiation → provider authorization → callback → shared success/failure handler) replacing the bespoke `mixin_auth` / `mixin` controller split.
- **FR-002**: The platform MUST exchange the authorization code for an access token and fetch the Mixin user profile using the provider strategy, equivalent to today's `User.auth_from_mixin` outcome.
- **FR-003**: The platform MUST upsert a `UserAuthorization` record keyed on `(provider: mixin, uid)` and update `access_token` and `raw` profile JSON on each successful sign-in.
- **FR-004**: The platform MUST resolve or create the associated `User` through shared logic: reuse existing user when authorization is linked; create new user with Mixin profile fields on first sign-in; refresh name and biography for messenger-linked users on repeat sign-in.
- **FR-005**: The platform MUST create a `Session` with request metadata and establish the browser session on successful Mixin sign-in, matching current post-login behavior including login notification.
- **FR-006**: The platform MUST support the `return_to` query parameter on OAuth initiation and redirect to a sanitized internal path after success or failure.
- **FR-007**: The platform MUST preserve the Mixin Messenger in-app browser experience: direct authorization redirect on the login page when detected, without requiring the modal intermediate step.
- **FR-008**: The platform MUST request only the `PROFILE:READ` Mixin OAuth scope (the legacy `COLLECTIBLES:READ` scope is dropped — Quill no longer needs Mixin collectibles access).
- **FR-009**: The platform MUST handle Mixin rate-limit responses during sign-in with a user-visible message and safe redirect — not an unhandled application error.
- **FR-010**: The platform MUST validate OAuth state on callback to prevent CSRF.
- **FR-011**: The platform MUST expose a single canonical callback route pattern per provider (e.g., `/auth/:provider/callback`) while maintaining backward-compatible redirects from existing callback URLs (`/auth/mixin/callback`, `/oauth/mixin/callback`).
- **FR-012**: The shared post-authentication pipeline MUST accept a normalized provider identity structure (provider name, uid, credentials, raw profile) so additional providers can plug in without duplicating session and user-resolution logic.
- **FR-013**: The platform MUST map provider identity to the existing `UserAuthorization` provider enum values (mixin as provider `0`) — no schema migration required for the Mixin migration itself.
- **FR-014**: Sign-in and OAuth callback actions MUST remain exempt from the launch gate so users can authenticate before public launch.
- **FR-015**: User-visible error and success messages for sign-in MUST use i18n locale keys (existing keys reused where applicable: connected, failed_to_connect, mixin_rate_limited).

### Key Entities

- **User**: Quill account; identified by `uid` (Mixin identity number for Mixin users), linked to one or more authorizations; receives profile updates on repeat Mixin sign-in.
- **UserAuthorization**: Links a third-party identity to a User; stores provider, uid, access_token, and raw provider profile JSON; unique on `(provider, uid)`.
- **Session**: Browser session record tied to a User; stores request info (IP, user agent) and optional provider metadata; referenced by `session[:current_session_id]`.
- **OAuth Provider Configuration**: Per-provider settings (client identifier, authorization endpoint, scopes, callback path) — Mixin first; additional providers added by configuration without rewriting the shared pipeline.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of existing Mixin sign-in entry points (connect-wallet modal, direct auth link, Mixin Messenger auto-redirect, `return_to` flows) complete successfully in staging with parity to pre-refactor behavior.
- **SC-002**: Repeat sign-in by an existing Mixin user reuses the same Quill user ID in 100% of test cases — zero duplicate users created for the same Mixin identity.
- **SC-003**: OAuth failure paths (denied auth, invalid callback, rate limit) produce a user-visible message and safe redirect within 2 seconds — no 500 errors in automated tests covering these scenarios.
- **SC-004**: Adding a second OAuth provider in a follow-up change requires no modifications to the shared session-creation or user-resolution pipeline — validated by architecture review and a stub provider integration test.
- **SC-005**: Legacy callback URLs continue to work for at least one release cycle after deploy, with zero reported sign-in failures attributable to URL changes in staging soak testing.
- **SC-006**: Automated test coverage exists for the shared authentication pipeline (happy path, existing user reuse, new user creation, rate limit, denied auth) — all tests pass in CI.

## Assumptions

- The `omniauth` library and `omniauth-mixin` strategy gem provide Mixin-specific authorization URL construction, token exchange, and profile normalization; they are the chosen implementation vehicles named in the feature request.
- Mixin remains the sole **login** provider after this refactor; Twitter account **linking** (dashboard connect flow) stays on its current custom implementation until a separate migration — but the shared pipeline MUST be designed so Twitter can adopt it later.
- No change to Mixin OAuth app registration is required beyond ensuring callback URLs include the new canonical path (legacy paths redirected).
- `UserAuthorization` schema and provider enum are sufficient for multi-provider support; no new tables are required for the Mixin migration.
- OAuth client credentials remain stored in existing encrypted credentials / settings patterns — not hard-coded in source.
- Mixin OAuth requests only `PROFILE:READ`; the former `COLLECTIBLES:READ` scope is intentionally removed (confirmed during planning).
- Login notification (`user.notify_for_login`) behavior is unchanged.
- API access tokens (`AccessToken` model for JSON API) are out of scope — this spec covers web session sign-in only.

## Out of Scope

- Migrating Twitter OAuth linking to the unified pipeline (future work; architecture must allow it).
- Adding new OAuth providers beyond Mixin in this feature (architecture and Mixin migration only).
- Changing primary login UI to show multiple provider buttons (UI remains Mixin-only until product adds providers).
- Password-based or email authentication.
- Changes to Mixin bot authentication, MixPay payment OAuth, or wallet PIN flows.
- Administrator authentication (`Admin::SessionsController`).
