# Research: Stale Transfer Management

**Feature**: 009-stale-transfer-management | **Date**: 2026-07-13

## 1. Stale State Representation

### Decision: Timestamp-based nullable column (`stale_at`)

Use a `stale_at` datetime column on `transfers` that is `NULL` for active transfers and set to the timestamp when marked stale.

**Rationale**:

- **Consistency with existing pattern**: The `Transfer` model already uses `processed_at` as the de facto state flag — `NULL` means unprocessed, non-`NULL` means processed. Using `stale_at` follows the same convention rather than introducing a new state machine (AASM) that `Transfer` currently doesn't use.
- **Simple scopes**: `unprocessed` becomes `where(processed_at: nil, stale_at: nil)` — one additional condition. No `state` column to migrate or backfill.
- **Built-in audit**: `stale_at` records when it was marked stale without needing a separate audit table.
- **Reversible**: Setting `stale_at = nil` reactivates the transfer naturally.

### Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| AASM `state` column (like `Order`) | Introduces a state machine where none exists today. Requires backfill of existing records. `processed_at` would become redundant. More invasive change for a binary flag. |
| Boolean `stale` column | Loses the audit timestamp. Would still need a separate `staled_at` or `staled_by_id` column, making the boolean redundant. |
| `stale_reason` text column | Out of scope for v1 per spec — manual admin action only, no auto-detection. Could be added later. |

## 2. Audit Trail (Who Marked as Stale)

### Decision: `staled_by_id` reference to `administrators`

Add a `staled_by_id :bigint` column referencing the `administrators` table.

**Rationale**:

- Spec FR-004 requires recording which admin performed the action.
- `Administrator` model already exists and is the actor class for admin actions.
- Foreign key constraint optional (keep it loose to avoid issues if an admin is later removed).
- No separate audit table needed — the `stale_at` + `staled_by_id` pair is sufficient for this feature's scope.

### Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| `acted_on` / `papertrail` audit gem | Overkill for a single attribute change. Adds a dependency. |
| Storing `current_admin_id` in `staled_by_id` only | Loses the timestamp for "when" — need `stale_at` separately. Both columns together provide complete audit. |

## 3. Scope Changes and Query Impact

### Decision: Modify `unprocessed` scope, add `stale` scope

```ruby
scope :unprocessed, -> { where(processed_at: nil).where(stale_at: nil) }
scope :stale, -> { where.not(stale_at: nil) }
```

Leave `processed` scope unchanged (`where.not(processed_at: nil)` — processed transfers don't care about staleness).

**Rationale**:

- Minimal diff: existing `unprocessed` consumers (jobs, controller) automatically exclude stale transfers.
- `process_pending!` uses `Transfer.unprocessed`, so stale transfers are immediately excluded from the recurring job.
- `Transfers::MonitorJob` also uses `unprocessed` scope, so stale transfers won't trigger monitor alerts.
- New `stale` scope enables the admin filter (FR-003).

### Performance: Composite Index

Add `add_index :transfers, [:processed_at, :stale_at]` so `unprocessed` queries use a single index scan.

**Rationale**:

- The `unprocessed` scope is the hot path (`process_pending!` runs every minute).
- The query `WHERE processed_at IS NULL AND stale_at IS NULL` benefits from a composite index on both columns.
- The existing single-column `index_transfers_on_processed_at` can be replaced or supplemented.

## 4. Admin UI Patterns

### Decision: Follow `process_now` pattern with Turbo Streams

Add two member routes following the existing `process_now` pattern:

| Route | Action | Turbo Stream Response |
|-------|--------|----------------------|
| `POST /admin/transfers/:id/stale` | `stale` | `stale.turbo_stream.erb` — replaces transfer row |
| `POST /admin/transfers/:id/reactivate` | `reactivate` | `reactivate.turbo_stream.erb` — replaces transfer row |

**Rationale**:

- Mirrors the existing `process_now` action which also uses Turbo Stream to replace the row partial.
- Both actions use `POST` (state-changing operations), consistent with Rails conventions.
- Row replacement via `turbo_stream.replace dom_id(@transfer)` re-renders the badge and action buttons inline without a full page refresh.
- The "Stale" button only appears for unprocessed transfers (guarded by `unless transfer.processed?`); "Reactivate" only appears for stale transfers.

### Filter State Options

Add "Stale" to the existing state `<select>` in `_query.html.erb`:

```erb
['Stale', 'stale']
```

Controller case statement:

```ruby
when "stale"
  transfers.stale
```

### Visual Badge

Use Tailwind `badge` classes:
- Stale: `badge badge-warning` (yellow) — distinct from success (green) and neutral (gray)

## 5. Locale Strategy

### Decision: Add admin-specific locale entries

Add to `config/locales/admin.en.yml` (or create if it doesn't exist):

```yaml
en:
  admin:
    transfers:
      state:
        stale: "Stale"
        unprocessed: "Unprocessed"
        processed: "Processed"
      actions:
        stale: "Mark Stale"
        reactivate: "Reactivate"
      confirm_stale: "Are you sure? This transfer will be excluded from all future processing."
```

**Rationale**: Constitution III requires i18n for new user-visible strings. Admin-specific strings are namespaced under `admin.transfers`.

## 6. Source-Associated Transfer Handling

### Decision: Keep source handling out of scope for v1

Per spec assumptions: "The stale marking does not affect any related records (Orders, Payments, Bonuses) beyond the transfer itself; handling of associated source objects is out of scope for v1."

**Rationale**: This avoids scope creep. The `stale` action on a transfer simply prevents it from being processed further. If the transfer is for a `payment_refund`, the Payment stays in its current state — admin can handle it separately. The Bonus `delivering` state and Order `:stale` AASM state already exist but are addressed in separate features.

## 7. Edge Case: Concurrent Processing

### Decision: Use row-level locking guard

When an admin marks a transfer as stale while `process_with_rescue!` holds a `FOR UPDATE NOWAIT` lock, the stale action will wait or handle the lock conflict gracefully.

**Rationale**:

- The controller uses `transfer.stale!` (model method) inside a transaction with `with_lock`.
- If another worker holds the lock, return a user-friendly flash message.
- The transfer will be `processed_at` (non-null) after processing completes, so marking as stale after processing would be a no-op anyway.

## Summary of Design Decisions

| # | Decision | Choice |
|---|----------|--------|
| 1 | Stale representation | `stale_at` datetime (NULL = not stale) |
| 2 | Audit trail | `staled_by_id` bigint reference to administrators |
| 3 | Scope strategy | Modify `unprocessed`, add `stale` scope |
| 4 | Index | Composite index on `[processed_at, stale_at]` |
| 5 | UI pattern | Turbo Stream row replacement (like `process_now`) |
| 6 | Badge style | `badge badge-warning` for stale |
| 7 | Locale | `config/locales/admin.en.yml` |
| 8 | Source handling | Out of scope for v1 |
