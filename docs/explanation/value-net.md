# The value net

> **30-second summary:** Every payment for an article is split three ways — 10% to the platform, 50% to the author, 40% pro-rata to **earlier readers** of that same article. Implemented in `Orders::DistributeService`; run as a background job per order.

## How the split works

On most Web3 publishing platforms, **first buyers** carry all the risk — paying before any social proof, missing the windfall if the article succeeds — so Quill reframes each article as a small economy rewarding readers who **went first**.

The 40% early-reader share divides pro-rata by what each earlier reader paid; tips count too (a tipper is a buyer for future rewards), so paying more increases both your share of future pools and the size of those pools.

### Worked example

Three readers pay `100 sats` each for article X, in order:

| Order | Platform (10%) | Author (50%) | Early-reader pool (40%) | Distribution |
|-------|---------------:|-------------:|------------------------:|--------------|
| A first | 10 | 90 | 0 | No earlier readers |
| B second | 10 | 45 | 40 | A is the only earlier reader → gets all 40 |
| C third | 10 | 45 | 40 | A and B paid equal → each gets 20 |

After C: A netted 150 sats, B 65, author 90. If D pays 200, the 80-sat pool splits proportionally across A, B, C's 300-sat history — each ~26.67 sats.

## Rules at the edge

- **One share per reader, not per order.** A reader who both *bought* and *rewarded* the same article folds together in `Orders::DistributeService#collect_early_readers`.
- **Mixed currencies fall back to BTC value.** When pool and order span different `asset_id`s, shares are weighted by `Order#value_btc` instead of `total`; only historical weights are converted (the new order joins in its own asset).
- **Below the floor, no transfer.** A share under `Orders::DistributeService::MINIMUM_AMOUNT` (`0.00000001`) rolls into author revenue; if the remainder is sub-floor, the author transfer is skipped too.
- **References and collections pay first.** `[Reference]` articles and the parent `[Collection]` are paid out of `total` **before** the 50/40 split; the author gets what's left.
- **Payout asset is `payment.asset_id`.** Multi-asset payment is handled by MixPay, settling in each item's own asset (4swap path is gone).

## Where it lives in the codebase

The split is implemented by [`Orders::DistributeService`](../../app/services/orders/distribute_service.rb), invoked per order via [`Orders::DistributeJob`](../../app/jobs/orders/distribute_job.rb) and flushed in batches by [`Orders::BatchDistributeJob`](../../app/jobs/orders/batch_distribute_job.rb). The service is idempotent and short-circuits on `Order#completed?`. `Order#order_type` distinguishes `:buy_article` and `:reward_article` (both count toward the early-reader pool) from `:cite_article` (which does not); the other key symbols are referenced inline in [Rules at the edge](#rules-at-the-edge).

## Settlement targets (post #1797)

Per-article and per-user Mixin wallets are no longer created — provisioning costs 0.5 USDT (`MixinBot::CREATE_USER_BILLING_INCREMENT`), and reading a wallet id must not silently spend money (#1790 §2.4). Existing rows stay for admin tooling; new wallets come only from the admin console.

| Recipient | Identity used (opponent) |
|-----------|--------------------------|
| **Platform fee** (`quill_revenue`) | `QuillBot.api.client_id` |
| **Author revenue** | `author.mixin_uuid` (from OAuth) |
| **Early-reader revenue** | `buyer.mixin_uuid` (login) |
| **Reference revenue** | `reference.author.mixin_uuid` (cited article's author) |
| **Collection revenue** | `_order.buyer.mixin_uuid` |

For article-order transfers the **source** (`transfers.wallet_id`) is the platform bot (`Orders::DistributeService#distributor_wallet_id = QuillBot.api.client_id`); for collection orders the source is `payment.wallet_id` (the buyer's Mixin identity).

## Further reading

- [Architecture](./architecture.md) — how the distribution fits into the system.
- [Reference → Background jobs](../reference/background-jobs.md#orders) — worker queue configuration.
