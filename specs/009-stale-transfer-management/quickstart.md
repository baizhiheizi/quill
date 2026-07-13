# Quickstart: Stale Transfer Management

**Feature**: 009-stale-transfer-management | **Date**: 2026-07-13

## Prerequisites

- Running Quill development environment (`bin/dev`)
- An admin account (`Administrator` record in database)
- At least one unprocessed transfer record

## Setup

```bash
bin/rails db:migrate
```

## Validation Scenarios

### 1. Mark a Transfer as Stale

1. Log in to the admin dashboard at `http://localhost:3000/admin`
2. Navigate to **Transfers** in the sidebar
3. Set the **State** filter to "Unprocessed"
4. Click **Query** to view unprocessed transfers
5. Find a transfer row and click **Mark Stale**
6. Confirm the prompt dialog
7. Verify:
   - The row updates in-place (Turbo Stream) without page reload
   - The State badge changes from "Unprocessed" (gray) to "Stale" (yellow)
   - The action buttons change from "Process / Mark Stale" to "Reactivate"
   - The transfer no longer appears when filtering by state "unprocessed"

### 2. Verify Stale Transfers Are Excluded from Processing

1. In the Rails console: `bin/rails console`
2. Find a stale transfer: `t = Transfer.stale.first`
3. Verify it has `stale_at` set and `processed_at` is nil
4. Run a manual process: `Transfer.process_pending!`
5. Verify the stale transfer was not processed: `t.reload.processed_at` is still nil
6. Verify the `unprocessed` scope excludes it: `Transfer.unprocessed.where(id: t.id).count` returns 0

### 3. Filter by Stale State

1. On the admin transfers page, set the **State** filter to "Stale"
2. Click **Query**
3. Verify:
   - Only transfers with a "Stale" badge are shown
   - Transfers with "Processed" or "Unprocessed" badges are excluded
4. Switch the filter back to "All State" — all transfers appear
5. Switch to "Unprocessed" — stale transfers are excluded

### 4. Reactivate a Stale Transfer

1. With the **State** filter set to "Stale," find a stale transfer
2. Click **Reactivate**
3. Verify:
   - The row updates in-place
   - The State badge changes back to "Unprocessed" (gray)
   - The "Process" and "Mark Stale" action buttons reappear
4. In Rails console: `t.reload.stale_at` is nil, `t.stale_by_id` is nil

### 5. Guard: Cannot Stale a Processed Transfer

1. Find a processed transfer (filter state "Processed")
2. Verify the **Mark Stale** button is not visible in the row
3. Verify the `stale?` method returns false: `Transfer.processed.first.stale?`

### 6. Verify Audit Trail

1. In Rails console, find a stale transfer: `t = Transfer.stale.first`
2. Verify `t.stale_at` is a timestamp
3. Verify `t.staled_by_id` references a valid `Administrator`

## Test Commands

```bash
# Model tests (scope changes, stale!/reactivate! methods)
bin/rails test test/models/transfer_test.rb

# Controller tests (stale/reactivate actions, filter behavior)
bin/rails test test/controllers/admin/transfers_controller_test.rb

# Full suite
bin/rails test

# Autoloading check
bin/rails zeitwerk:check
```

## Expected Outcomes

| Scenario | Expected Result |
|----------|----------------|
| Stale a transfer | Row updates, badge shows "Stale", excluded from `unprocessed` |
| `process_pending!` skips stale transfers | Stale transfers remain unprocessed after batch run |
| Filter by "Stale" state | Only stale transfers shown |
| Reactivate a stale transfer | Row updates, badge shows "Unprocessed", eligible for processing |
| Can't stale processed | No button shown for processed transfers |
| Can't reactivate processed | No button shown for processed transfers |
| Audit trail | `stale_at` and `staled_by_id` populated on stale action |
