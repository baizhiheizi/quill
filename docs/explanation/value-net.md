# The value net

> **30-second summary:** Every payment for an article is split three ways — 10% to the platform, 50% to the author, and 40% to the **earlier readers** of that same article, distributed pro-rata by how much each earlier reader paid. The mechanism is implemented in `Orders::DistributeService` and run as a background job per order.

## The problem with traditional publishing

On most Web3 publishing platforms, **first buyers** carry all the risk: they pay before any social proof of value. If the article succeeds, the windfall goes to the author and the early backers are forgotten.

Quill reframes the article as a small economy — every new payment compensates the readers who **went first**, sharing the value with the people whose early conviction unlocked it.

## How the split works

For every order on an article:

| Recipient | Share |
|-----------|-------|
| **Platform** handling fee | 10% |
| **Article author** | 50% |
| **Early readers** (all previous readers of this article) | 40% |

The 40% early-reader share is divided proportionally to what each earlier reader originally paid. Rewards behave the same way: a reader who tips an article also counts as a buyer when later readers are rewarded. Higher payment on the same article increases both a reader's share of every future early-reader pool and the size of the pool itself.

### Worked example

Imagine three readers, A, B, and C, each paying `100 sats` for article X in order.

| Order | Total paid | Platform 10% | Author 50% | Early-reader pool 40% | Distribution |
|-------|-----------:|-------------:|-----------:|----------------------:|--------------|
| A first | 100 | 10 | 90 | 0 | A is the only reader → no one to reward |
| B second | 100 | 10 | 45 | 40 | A is the sole earlier reader → A gets all 40 |
| C third | 100 | 10 | 45 | 40 | A and B are earlier readers (paid equal) → each gets 20 |

After C, A has netted 150 sats, B 65 sats, and the author 90 sats from two equal-price sales.

If D pays 200 sats, the pool becomes 80 sats, split proportionally (A: 100, B: 100, C: 100, total 300), so each of A, B, C gets `80 × 100/300 ≈ 26.67` sats.

## Rules at the edge

The worked example above assumes every order is paid in the same currency. The real implementation has a few extra rules worth knowing:

- **One share per reader, not per order.** A reader who both *bought* and *rewarded* the same article is treated as a single early reader: their orders are folded together in `Orders::DistributeService#collect_early_readers`, which emits a single reader-revenue transfer keyed on the sorted order trace ids + the new order's trace id.
- **Mixed currencies fall back to BTC value.** When the early-reader pool and the incoming order span different `asset_id`s, the service switches from `total` to `Order#value_btc` for share weighting, keeping the pro-rata split fair across currencies (BTC, USDT, XIN, …). The current order always joins the pool in its own asset — only the historical weights are converted.
- **Below the floor, no transfer.** A reader's computed share is skipped when it is below `Orders::DistributeService::MINIMUM_AMOUNT` (`0.00000001`). Sub-floor amounts are absorbed into the author revenue for the order — the author line is `total − readers − quill − references − collection`, so any skipped reader share is implicitly added back to the author. The author transfer is itself skipped if the remainder is sub-floor.
- **Reference and collection revenue are computed first.** `[Reference]` articles (via `Article#article_references`) and the parent `[Collection]` (via `Collection#collection_revenue_ratio`) are paid out of the order total **before** the 50/40 author/early-reader split, then the author gets whatever is left. A 10% platform cut is always subtracted from the gross `total`.
- **The paid asset may not be the payout asset.** When the buyer's payment went through Mixin Pay with a swap, the revenue is paid out in `payment.swap_order&.fill_asset_id`; otherwise it is paid in `payment.asset_id`. The early-reader pool's *historical* weights are still denominated in the order's own `total` or `value_btc` — the swap only affects the *output* asset.

## Where it lives in the codebase

The split is implemented by [`Orders::DistributeService`](../../app/services/orders/distribute_service.rb) and invoked per order via [`Orders::DistributeJob`](../../app/jobs/orders/distribute_job.rb). Batches of pending orders are flushed by [`Orders::BatchDistributeJob`](../../app/jobs/orders/batch_distribute_job.rb). The service is idempotent and short-circuits on `Order#completed?`.

| Symbol | Purpose |
|--------|---------|
| `Order#order_type` | `:buy_article`, `:reward_article`, or `:cite_article`. Only the first two count toward the early-reader pool; `cite_article` is a *reference* payment and never makes the citer an early reader. |
| `Order#value_btc` | BTC-equivalent value at payment time. Used to weight shares when the pool spans multiple currencies. |
| `Order#complete!` | Marks the order as distributed so it cannot be paid twice. |
| `Orders::DistributeService::MINIMUM_AMOUNT` | `0.00000001`. Both the per-reader transfer and the author transfer skip when their amount is below this floor. |
| `Orders::DistributeService#collect_early_readers` | Returns `{ mixin_uuid => [trace_id, ...] }`. Iterating this hash, rather than the raw `early_orders`, is what enforces the one-share-per-reader rule. |

## Further reading

- [README](../../README.md) for the user-facing description.
- [Architecture](./architecture.md) for how the distribution fits into the rest of the system.
- [Reference → Background jobs](../reference/background-jobs.md#orders) for the worker queue configuration.
