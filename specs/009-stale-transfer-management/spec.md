# Feature Specification: Stale Transfer Management

**Feature Branch**: `009-stale-transfer-management`

**Created**: 2026-07-13

**Status**: Draft

**Input**: User description: "The Mixin Network has been upgraded many times, there're many stale transfers @app/models/transfer.rb in the database, and they will be retried again and again. We need handle these. We need be able mark some transfer as stale, put them out of the process queue."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Mark Transfer as Stale (Priority: P1)

An administrator reviews the transfers list and identifies transfers that can never succeed (e.g., due to Mixin Network upgrades making the recipient format obsolete, or permanently unreachable recipients). The admin must be able to mark one or more transfers as "stale," which immediately removes them from the processing queue so they are never retried again.

**Why this priority**: This is the core action that stops the repeated, wasteful retry cycle. Without it, stale transfers continue consuming API quota, job queue capacity, and log noise indefinitely.

**Independent Test**: Can be fully tested by marking a pending transfer as stale via the admin interface and verifying it no longer appears in the processing queue or gets picked up by the recurring processor.

**Acceptance Scenarios**:

1. **Given** an unprocessed transfer exists in the system, **When** an admin marks it as stale, **Then** the transfer is immediately excluded from `process_pending!` batch processing and the monitor job.
2. **Given** a transfer marked as stale, **When** the recurring `Transfers::ProcessPendingJob` runs, **Then** the stale transfer is not picked up for processing.
3. **Given** an already-processed transfer, **When** an admin attempts to mark it as stale, **Then** the system prevents this action (only unprocessed transfers can be staled).

---

### User Story 2 - View and Filter Stale Transfers (Priority: P2)

An administrator needs visibility into which transfers have been marked as stale — how many, when they were staled, and what type they are. The admin transfer list should support filtering by stale status.

**Why this priority**: Visibility is essential for auditing and for deciding whether stale transfers need further action (e.g., re-creating via a different mechanism). Without filtering, admins cannot easily find or review stale transfers.

**Independent Test**: Can be fully tested by marking several transfers as stale and verifying they appear under a "stale" filter in the admin transfers index, while non-stale transfers are excluded from that filtered view.

**Acceptance Scenarios**:

1. **Given** some transfers are marked as stale, **When** an admin filters the transfer list by state "stale," **Then** only stale transfers are displayed.
2. **Given** the admin transfer list loads, **When** the state filter is set to "unprocessed," **Then** stale transfers are excluded (they have their own filter category).
3. **Given** a stale transfer row in the admin list, **When** admins view the row, **Then** the stale status is visually distinct (e.g., a dedicated badge or label).

---

### User Story 3 - Reactive a Stale Transfer (Priority: P3)

An admin may mark a transfer as stale prematurely or the underlying issue (e.g., recipient registers their Safe wallet) may be resolved later. The admin must be able to "un-stale" a transfer, returning it to the normal unprocessed queue for retry.

**Why this priority**: This is a recovery path. The primary value is in stopping the retry loop (P1); reversal is lower urgency but important for operational flexibility.

**Independent Test**: Can be fully tested by marking a transfer as stale, then reactivating it, and verifying it becomes eligible for processing again.

**Acceptance Scenarios**:

1. **Given** a transfer is marked as stale, **When** an admin reactivates it, **Then** the transfer returns to the unprocessed state and is eligible for the next `process_pending!` batch.
2. **Given** a reactivated transfer, **When** `process_pending!` runs, **Then** the transfer is picked up and processed normally.

---

### Edge Cases

- What happens when an admin tries to stale a transfer that is currently being processed (locked by another worker)? The system should handle the lock conflict gracefully and inform the admin.
- What happens when a transfer with an associated source (Payment, Bonus) is marked stale? The source's state must be considered — a Payment waiting for refund should still allow manual refund, while a Bonus should not remain in `delivering` state indefinitely.
- What happens when bulk-staling a large number of transfers? The system should handle this efficiently without blocking the admin interface.
- What happens with transfers that have a `retry_at` set in the future? Marking them as stale should override any pending retry schedule and remove them from the queue immediately.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Administrators MUST be able to mark an unprocessed transfer as "stale" from the admin interface, which permanently excludes it from automated processing (both `process_pending!` and the monitor).
- **FR-002**: The `unprocessed` scope and `process_pending!` method MUST exclude transfers marked as stale, so stale transfers are never picked up by recurring jobs.
- **FR-003**: The admin transfer list MUST support filtering by state, including a "stale" filter distinct from "processed" and "unprocessed."
- **FR-004**: Each stale transfer MUST record when it was marked as stale and which admin performed the action (audit trail).
- **FR-005**: Administrators MUST be able to reactivate (un-stale) a transfer, returning it to eligible unprocessed status.
- **FR-006**: Only unprocessed transfers MAY be marked as stale; already-processed transfers MUST NOT be eligible for stale marking.
- **FR-007**: The transfer row in the admin list MUST visually distinguish stale transfers from processed, unprocessed, and retry-scheduled transfers.
- **FR-008**: When a transfer is marked as stale, its `retry_at` value MUST be cleared so no deferred retry schedule remains active.

### Key Entities

- **Transfer**: Represents a Mixin Network fund transfer. Gains a stale status to indicate it should no longer be processed. Key attributes: stale flag/timestamp, stale-by (admin reference), staleness is exclusive with processed status.
- **Administrator**: The actor who marks transfers as stale or reactivates them. Each stale action is attributed to a specific admin for audit purposes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Administrators can mark a transfer as stale in under 10 seconds from the transfer list view.
- **SC-002**: After marking a transfer as stale, it is never processed by any automated job (zero stale transfers in processing logs).
- **SC-003**: Admins can filter and view all stale transfers in the admin interface without performance degradation for lists up to 10,000 transfers.
- **SC-004**: Stale transfers no longer contribute to API rate limit consumption — the recurring `process_pending!` job skips them entirely.
- **SC-005**: No transfer is accidentally staled — the system displays a confirmation prompt before marking.

## Assumptions

- The "stale" action is performed manually by administrators through the admin dashboard; there is no automatic staleness detection in this feature.
- A transfer marked as stale is considered a terminal state for that transfer record (no further automated processing), but can be reversed manually.
- The stale marking does not affect any related records (Orders, Payments, Bonuses) beyond the transfer itself; handling of associated source objects (e.g., transitioning a Payment from refunding) is out of scope for v1.
- The existing admin authentication and authorization for the transfers section (`Admin::TransfersController`) is sufficient — no new permission model is introduced.
- Stale transfers are excluded from `Transfer.stats` and revenue calculations since they represent transfers that never completed.
