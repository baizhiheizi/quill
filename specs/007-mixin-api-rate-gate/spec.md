# Feature Specification: Global Mixin API Rate Gating

**Feature Branch**: `007-mixin-api-rate-gate` (not yet created — no branch-creation hook is configured in this workspace; create manually before implementing if desired)

**Created**: 2026-07-05

**Status**: Draft

**Input**: User description: "Let's gate the Mixin API requests globally. Like 429 error." (triggered by `MixinBot::RateLimitError` on snapshot polling — `GET /safe/snapshots`, errcode 429, Too Many Requests — crashing the long-running payment-ingestion worker.)

*(Quill integrates with the Mixin network across many concurrent paths: snapshot polling for incoming payments, transfer settlement, bot notifications, OAuth login, wallet operations, and per-user API clients. Today each caller issues requests independently with local retry logic. When the Mixin service returns HTTP 429 (Too Many Requests), some workers lack dedicated handling and can fail or spin in tight retry loops. Competing callers amplify the problem — e.g., aggressive snapshot polling alongside transfer processing and notification bursts. This spec defines a single, platform-wide gate that proactively throttles outbound Mixin traffic and reactively backs off on rate-limit responses so payment and settlement flows remain reliable.)*

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Payment Ingestion Survives Rate Limits (Priority: P1)

As the platform, when the Mixin service signals that request volume is too high (HTTP 429), incoming payment snapshot polling MUST pause and resume automatically without crashing the ingestion worker or permanently skipping payments.

**Why this priority**: Snapshot polling is the entry point for all crypto payments. An unhandled 429 stops payment detection entirely, blocking reader purchases and author revenue.

**Independent Test**: Simulate sustained 429 responses from the Mixin snapshot endpoint while the payment-ingestion worker runs; verify the worker stays alive, logs the rate-limit event, backs off, and resumes processing snapshots once limits clear — with no duplicate or lost snapshot records.

**Acceptance Scenarios**:

1. **Given** the payment-ingestion worker is polling snapshots, **When** the Mixin service returns 429, **Then** the worker does not crash and does not enter an unbounded tight retry loop.
2. **Given** a 429 response during snapshot polling, **When** the rate-limit window passes, **Then** polling resumes from the last successfully processed offset with no gaps in snapshot coverage.
3. **Given** multiple consecutive 429 responses, **When** backoff is applied, **Then** wait intervals increase progressively up to a configured maximum before retrying.
4. **Given** a 429 on snapshot polling, **When** a payment snapshot arrives during the backoff window, **Then** it is picked up on the next successful poll (no permanent loss attributable to the rate limit).

---

### User Story 2 - All Mixin Callers Share One Global Gate (Priority: P2)

As the platform, every outbound Mixin API call — regardless of which feature initiated it (transfers, notifications, OAuth, wallet sync, admin tools) — MUST pass through the same rate gate so callers do not compete against each other and trigger avoidable 429 errors.

**Why this priority**: Local per-feature retry logic cannot prevent cross-feature contention. A global gate is the only way to stay under Mixin's quota when snapshot polling, transfer settlement, and notification delivery run concurrently.

**Independent Test**: Run snapshot polling and transfer processing concurrently under a simulated low rate budget; verify total outbound request rate stays within the configured limit and neither feature monopolizes the quota.

**Acceptance Scenarios**:

1. **Given** snapshot polling and transfer settlement are both active, **When** combined request volume approaches the configured limit, **Then** new requests are queued or delayed rather than sent immediately.
2. **Given** a burst of notification deliveries during active snapshot polling, **When** the gate is near capacity, **Then** notifications are deferred without failing permanently or dropping delivery intent.
3. **Given** separate bot identities (platform bot and revenue bot) and per-user API clients, **When** requests are issued, **Then** each credential scope is gated independently so one scope hitting its limit does not block unrelated scopes.
4. **Given** a deferred request waiting in the gate, **When** capacity becomes available, **Then** the request proceeds in fair order relative to other waiting callers (no permanent starvation of low-priority paths like notifications vs. payments).

---

### User Story 3 - Transfer and Settlement Continue After Rate Limits (Priority: P2)

As a reader or author awaiting a payment or payout, when the Mixin service rate-limits transfer-related calls, my order or transfer MUST eventually complete without manual intervention once limits clear.

**Why this priority**: Transfers move money to authors and early readers. A 429 during `create_safe_transfer` or transaction lookup must not mark a transfer as permanently failed.

**Independent Test**: Enqueue a transfer while the Mixin service returns 429 on transfer endpoints; verify the transfer remains in a retryable state and completes successfully after the rate limit lifts.

**Acceptance Scenarios**:

1. **Given** an unprocessed transfer, **When** the Mixin service returns 429 on a transfer call, **Then** the transfer is not marked as processed and will be retried.
2. **Given** a 429 during transfer processing, **When** backoff completes, **Then** the transfer is attempted again without duplicate on-chain transactions (idempotent by trace/request ID).
3. **Given** multiple pending transfers during a rate-limit event, **When** capacity returns, **Then** transfers are processed in their existing priority order without indefinite blocking of any single transfer.

---

### User Story 4 - Operators Can Observe Rate-Limit Health (Priority: P3)

As a platform operator, I can tell when the Mixin API gate is throttling or backing off so I can distinguish normal transient limits from a sustained outage or misconfiguration.

**Why this priority**: Without visibility, operators cannot tell whether delayed payments are due to rate limits, Mixin downtime, or application bugs.

**Independent Test**: Trigger a rate-limit event in a staging environment; verify structured log entries (or equivalent observability signal) record the affected endpoint, credential scope, backoff duration, and recovery — without exposing secrets.

**Acceptance Scenarios**:

1. **Given** the gate applies backoff due to 429, **When** an operator reviews logs, **Then** they see a clear rate-limit event with timestamp, endpoint category, and planned retry delay.
2. **Given** proactive throttling is active (approaching limit before 429), **When** an operator reviews metrics, **Then** they can see current request rate vs. configured limit per credential scope.
3. **Given** a sustained rate-limit period exceeding 10 minutes, **When** an operator checks system health, **Then** they can distinguish "rate limited but recovering" from "worker crashed" or "Mixin service down."

---

### Edge Cases

- What happens when the Mixin service returns 429 without a `Retry-After` header or equivalent hint? The gate MUST apply exponential backoff with jitter using configured defaults.
- What happens when only one credential scope (e.g., revenue bot) is rate limited while the platform bot is healthy? Other scopes MUST continue unaffected.
- What happens when a long-running poll loop and a background job both retry the same endpoint after 429? The global gate MUST deduplicate or serialize so retry storms do not amplify the limit breach.
- What happens when the gate's configured limit is set too aggressively (always throttling)? Operators MUST be able to tune limits without redeploying application code (via configuration).
- What happens when a 429 occurs on a user-initiated synchronous action (e.g., login via OAuth)? The user MUST see a friendly, retryable error — not a generic server crash or infinite spinner.
- What happens during Mixin service maintenance (sustained 429 or 5xx for hours)? Work MUST queue safely; no data loss; workers remain alive; operators receive observable signals.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The platform MUST route all outbound Mixin API requests through a single global rate gate before they reach the Mixin service.
- **FR-002**: The gate MUST enforce a configurable maximum request rate per credential scope (platform bot, revenue bot, per-user client).
- **FR-003**: When the Mixin service returns HTTP 429 (Too Many Requests), the gate MUST pause further requests for that credential scope and apply backoff before retrying.
- **FR-004**: Backoff on 429 MUST use increasing delays with a configurable ceiling; when the Mixin service provides a retry hint, the gate MUST honor it.
- **FR-005**: The gate MUST queue or defer requests that exceed the configured rate rather than sending them immediately and relying on 429 as the only signal.
- **FR-006**: Rate-limit handling MUST NOT permanently fail payment snapshot ingestion, transfer settlement, or notification delivery — all MUST retry until success or an existing business-level expiry rule applies.
- **FR-007**: Long-running workers (payment ingestion, transfer processing) MUST NOT terminate due to an unhandled rate-limit response.
- **FR-008**: Transfer and payment operations MUST remain idempotent across rate-limit retries (no duplicate on-chain transactions from repeated attempts).
- **FR-009**: User-initiated synchronous Mixin calls (login, wallet actions) MUST return a clear, retryable error message when rate limited, without exposing internal details.
- **FR-010**: The gate MUST log rate-limit events and throttle activity at a level sufficient for operators to diagnose incidents (endpoint category, scope, backoff duration, recovery).
- **FR-011**: Rate-limit configuration (requests per interval, max backoff, scope definitions) MUST be adjustable via application configuration without code changes.
- **FR-012**: Existing local retry logic in individual features MAY remain for non-rate-limit errors but MUST defer to the global gate for 429 handling to avoid competing retry strategies.

### Key Entities

- **Rate Gate**: The platform-wide coordinator that admits, delays, or rejects outbound Mixin requests based on current usage and rate-limit state per credential scope.
- **Credential Scope**: A distinct Mixin API identity whose rate budget is tracked independently (e.g., platform bot, revenue bot, individual user wallet API).
- **Rate-Limit Event**: A recorded occurrence when the Mixin service returns 429 or the gate proactively throttles; includes scope, time, affected operation category, and backoff applied.
- **Deferred Request**: An outbound Mixin call waiting for gate capacity or backoff expiry before execution.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Payment-ingestion workers run continuously for 7 days without restart caused by unhandled Mixin rate-limit errors.
- **SC-002**: 100% of payment snapshots that arrive during a rate-limit window are ingested within 5 minutes of the limit clearing (no permanent gaps attributable to 429).
- **SC-003**: 99% of rate-limited outbound requests (those receiving 429) succeed on retry within 5 minutes under normal Mixin service availability.
- **SC-004**: Concurrent Mixin callers (snapshot polling + transfer processing + notifications) operate without rate-limit error rates exceeding 1% of total outbound requests during steady-state production load.
- **SC-005**: Zero duplicate on-chain transfer transactions caused by rate-limit retry logic over a 30-day observation window.
- **SC-006**: Operators can identify a rate-limit incident and its recovery time from logs within 2 minutes of investigation (no code archaeology required).

## Assumptions

- The Mixin network enforces per-application rate limits; exact quotas are not published and may change — the gate MUST be tunable via configuration.
- Quill uses at least two bot credential scopes (platform bot and revenue bot) plus occasional per-user API clients; each scope has an independent rate budget on the Mixin side.
- Proactive throttling (stay below limit before 429) combined with reactive backoff (on 429) is the default strategy; reactive-only is insufficient given concurrent long-running workers.
- User-facing impact of rate limits on synchronous flows (login) is rare; a friendly retry message is acceptable rather than silent queuing with long waits.
- Existing idempotency keys (trace IDs, request IDs, snapshot IDs) are sufficient to prevent duplicate financial operations during retries — the gate does not introduce new idempotency mechanisms.
- This feature is infrastructure-only; no new user-facing UI is required beyond improved error messages on synchronous paths.
- Rate-limit configuration defaults will be conservative (prefer slight under-utilization over hitting 429) and tuned in production based on observed traffic.
