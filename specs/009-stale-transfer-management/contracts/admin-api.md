# Admin Transfer Actions Contract

**Feature**: 009-stale-transfer-management | **Date**: 2026-07-13

## Routes

| Method | Path | Action | Description |
|--------|------|--------|-------------|
| `POST` | `/admin/transfers/:id/stale` | `stale` | Mark an unprocessed transfer as stale |
| `POST` | `/admin/transfers/:id/reactivate` | `reactivate` | Re-activate a stale transfer back to unprocessed |

Both routes are mounted as member routes on the existing `resources :transfers` block in `config/routes/admin.rb`.

## POST /admin/transfers/:transfer_id/stale

**Purpose**: Mark an unprocessed transfer as stale, excluding it from all future automated processing.

**Authentication**: Admin session required (`authenticate_admin!` before_action from `Admin::BaseController`).

### Request

- **Content-Type**: `text/html` (standard form POST or Turbo Stream)
- **Parameters**: None beyond route parameter `:transfer_id`

### Success Response (Turbo Stream)

- **Status**: `200 OK`
- **Content-Type**: `text/vnd.turbo-stream.html`
- **Body**: Replaces `#transfer_<id>` row in the table with updated partial showing the stale badge

### Failure Responses

| Scenario | Status | Behavior |
|----------|--------|----------|
| Transfer not found | `404 Not Found` | Standard Rails `ActiveRecord::RecordNotFound` |
| Transfer already processed | `422 Unprocessable Entity` | Flash alert: "Cannot mark a processed transfer as stale" |
| Transfer already stale | `200 OK` (idempotent) | Re-render row (no-op) |
| Row locked by another worker | `409 Conflict` | Flash alert: "Transfer is currently being processed, try again" |
| Not authenticated | `302 Found` | Redirect to `/admin/login` |

### Side Effects

- Sets `transfer.stale_at = Time.current`
- Sets `transfer.staled_by_id = current_admin.id`
- Sets `transfer.retry_at = nil` (clears any pending retry schedule)
- Transfer is immediately excluded from `Transfer.unprocessed` scope
- No notification or callback to recipient/source

## POST /admin/transfers/:transfer_id/reactivate

**Purpose**: Return a stale transfer to the unprocessed state, making it eligible for processing again.

**Authentication**: Admin session required.

### Request

- **Content-Type**: `text/html`
- **Parameters**: None beyond route parameter `:transfer_id`

### Success Response (Turbo Stream)

- **Status**: `200 OK`
- **Content-Type**: `text/vnd.turbo-stream.html`
- **Body**: Replaces `#transfer_<id>` row in the table showing "Unprocessed" badge and "Process"/"Stale" action buttons

### Failure Responses

| Scenario | Status | Behavior |
|----------|--------|----------|
| Transfer not found | `404 Not Found` | Standard Rails `ActiveRecord::RecordNotFound` |
| Transfer already processed | `422 Unprocessable Entity` | Flash alert: "Cannot reactivate a processed transfer" |
| Transfer not stale | `422 Unprocessable Entity` | Flash alert: "Transfer is not marked as stale" |

### Side Effects

- Sets `transfer.stale_at = nil`
- Sets `transfer.staled_by_id = nil`
- Transfer becomes eligible in next `process_pending!` batch (via `unprocessed` scope)

## Admin Filter: State Select

The existing state filter (`_query.html.erb`) gains a "Stale" option:

| Value | Controller Action | Scope Used |
|-------|-------------------|------------|
| `all` | All transfers (existing) | `Transfer.all` |
| `unprocessed` | Unprocessed, non-stale (existing, modified) | `Transfer.unprocessed` |
| `processed` | Processed (existing, unchanged) | `Transfer.processed` |
| **`stale`** | **Stale transfers** (new) | **`Transfer.stale`** |

## Admin Row Partial: Badge State Matrix

The `_transfer.html.erb` partial renders badges based on:

| Condition | Badge Class | Label |
|-----------|-------------|-------|
| `transfer.processed?` | `badge badge-success` | Processed |
| `transfer.stale?` | `badge badge-warning` | Stale |
| Otherwise (unprocessed) | `badge badge-neutral` | Unprocessed |

## Admin Row Partial: Action Buttons

| Condition | Buttons Shown |
|-----------|--------------|
| `transfer.processed?` | Detail only |
| `transfer.stale?` | Detail, Reactivate |
| Otherwise (unprocessed, active) | Detail, Process, Mark Stale |
