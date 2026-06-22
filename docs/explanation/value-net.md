# The value net

> **30-second summary:** Every payment for an article is split three ways — 10% to the platform, 50% to the author, and 40% to the **earlier readers** of that same article, distributed pro-rata by how much each earlier reader paid. The mechanism is implemented in `Orders::DistributeService` and run as a background job per order.

## The problem with traditional publishing

On most Web3 publishing platforms, **first buyers** carry all the risk: they pay before any social proof of value. If the article succeeds, the windfall goes to the author and the early backers are forgotten.

Quill reframes the article as a small economy — every new payment compensates the readers who **went first**, sharing the value with the people whose early conviction unlocked it.

## How the split works

The 40% early-reader share is divided pro-rata by what each earlier reader originally paid. Rewards follow the same rule — a reader who tips an article also counts as a buyer when later readers are rewarded — so a higher payment on the same article increases both that reader's share of every future early-reader pool and the size of the pool itself.

### Worked example

Three readers, A, B, and C, each pay `100 sats` for article X in order:

| Order | Platform 10% | Author 50% | Early-reader pool 40% | Distribution |
|-------|-------------:|-----------:|----------------------:|--------------|
| A first | 10 | 90 | 0 | A is the only reader → no one to reward |
| B second | 10 | 45 | 40 | A is the sole earlier reader → A gets all 40 |
| C third | 10 | 45 | 40 | A and B are earlier readers (paid equal) → each gets 20 |

After C, A has netted 150 sats, B 65 sats, and the author 90 sats from two equal-price sales. If D then pays 200 sats, the 80-sat pool is split proportionally across A, B, and C's combined 300-sat history, giving each roughly `26.67` sats.

## Rules at the edge

The worked example assumes every order is paid in the same currency. The real implementation has a few extra rules:

- **One share per reader, not per order.** A reader who both *bought* and *rewarded* the same article is treated as a single early reader: their orders are folded together in `Orders::DistributeService#collect_early_readers`, which emits a single reader-revenue transfer keyed on the sorted order trace ids plus the new order's trace id.
- **Mixed currencies fall back to BTC value.** When the early-reader pool and the incoming order span different `asset_id`s, the service switches from `total` to `Order#value_btc` for share weighting, keeping the pro-rata split fair across currencies (BTC, USDT, XIN, …). The current order always joins the pool in its own asset; only the historical weights are converted.
- **Below the floor, no transfer.** A reader's share is skipped when it is below `Orders::DistributeService::MINIMUM_AMOUNT` (`0.00000001`). Sub-floor amounts roll into the author revenue (the author line is `total − readers − quill − references − collection`); the author transfer is itself skipped if the remainder is sub-floor.
- **Reference and collection revenue are computed first.** `[Reference]` articles (via `Article#article_references`) and the parent `[Collection]` (via `Collection#collection_revenue_ratio`) are paid out of the order total **before** the 50/40 split; the author gets whatever is left.
- **The paid asset may not be the payout asset.** When the buyer's payment went through Mixin Pay with a swap, revenue is paid out in `payment.swap_order&.fill_asset_id`; otherwise it is paid in `payment.asset_id`. The swap only affects the *output* asset — the early-reader pool's *historical* weights are still denominated in the order's own `total` or `value_btc`.

## Where it lives in the codebase

The split is implemented by [`Orders::DistributeService`](../../app/services/orders/distribute_service.rb), invoked per order via [`Orders::DistributeJob`](../../app/jobs/orders/distribute_job.rb) and flushed in batches by [`Orders::BatchDistributeJob`](../../app/jobs/orders/batch_distribute_job.rb). The service is idempotent and short-circuits on `Order#completed?`.

Key symbols: `Order#order_type` distinguishes the three kinds of payment (`:buy_article` and `:reward_article` count toward the early-reader pool, `:cite_article` does not); `Order#value_btc` weights shares across mixed currencies; `Order#complete!` marks an order as distributed; `Orders::DistributeService::MINIMUM_AMOUNT` (`0.00000001`) is the sub-floor skip threshold for both per-reader and author transfers; and `Orders::DistributeService#collect_early_readers` (returning `{ mixin_uuid => [trace_id, ...] }`) is the hash whose iteration enforces the one-share-per-reader rule.

## Further reading

- [README](../../README.md) for the user-facing description.
- [Architecture](./architecture.md) for how the distribution fits into the rest of the system.
- [Reference → Background jobs](../reference/background-jobs.md#orders) for the worker queue configuration.
