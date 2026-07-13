# Data Model: Stale Transfer Management

**Feature**: 009-stale-transfer-management | **Date**: 2026-07-13

## Entity: Transfer

### New Columns

| Column | Type | Default | Nullable | Description |
|--------|------|---------|----------|-------------|
| `stale_at` | `datetime` | `NULL` | YES | When the transfer was marked stale. `NULL` = active/not stale. |
| `staled_by_id` | `bigint` | `NULL` | YES | Reference to `administrators.id` — the admin who performed the action. |

### New Index

| Name | Columns | Type |
|------|---------|------|
| `index_transfers_on_processed_at_and_stale_at` | `[:processed_at, :stale_at]` | B-tree |

### State Rules

| Condition | State |
|-----------|-------|
| `processed_at IS NULL AND stale_at IS NULL` | **Unprocessed** (eligible for processing) |
| `processed_at IS NOT NULL` | **Processed** (regardless of stale status) |
| `stale_at IS NOT NULL AND processed_at IS NULL` | **Stale** (excluded from processing) |
| `stale_at IS NOT NULL AND processed_at IS NOT NULL` | **Processed** (stale flag is irrelevant once processed) |

**Constraint (application-level)**: Only transfers with `processed_at IS NULL` may be marked stale. Once marked stale, they cannot be processed (processing is blocked). Processing takes precedence — if a transfer somehow becomes both, it's treated as `processed`.

### New Scopes

```ruby
# Modified — excludes stale transfers
scope :unprocessed, -> { where(processed_at: nil).where(stale_at: nil) }

# New — stale-only transfers
scope :stale, -> { where.not(stale_at: nil) }

# Unchanged
scope :processed, -> { where.not(processed_at: nil) }
```

### New Methods

| Method | Description |
|--------|-------------|
| `stale!(admin)` | Marks transfer as stale: sets `stale_at`, `staled_by_id`, clears `retry_at`. Guarded: raises if `processed?` is true. |
| `reactivate!` | Reverses staleness: sets `stale_at` and `staled_by_id` to `nil`. Guarded: raises if `processed?` is true. |
| `stale?` | Returns `stale_at.present?` |

### Lifecycle Transitions

```
[Created] → unprocessed → processed
                  ↓
               stale
                  ↓
              reactivate → unprocessed → processed
```

- Once `processed`, the transfer is terminal — no stale/reactivate transitions.
- `stale` state is terminal for automated processing but reversible by admin.

### Affected Queries

| Query | Before | After |
|-------|--------|-------|
| `Transfer.unprocessed` | `WHERE processed_at IS NULL` | `WHERE processed_at IS NULL AND stale_at IS NULL` |
| `Transfer.processed` | `WHERE processed_at IS NOT NULL` | unchanged |
| Admin state filter "unprocessed" | `Transfer.unprocessed` | unchanged (scope handles exclusion) |
| Admin state filter "stale" | N/A | `Transfer.stale` (new) |
| `process_pending!` | `Transfer.unprocessed.where(...)` | unchanged (scope handles exclusion) |
| `Transfers::MonitorJob` | `Transfer.unprocessed.where(...)` | unchanged (scope handles exclusion) |

## Entity: Administrator

No changes. Existing `Administrator` model is referenced by `staled_by_id`.

### Relationship

```
Administrator (1) ──── (*) Transfer (staled_by_id)
```

No `has_many :staled_transfers` association is added to `Administrator` in v1 (no current admin view requires it).
