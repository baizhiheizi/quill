# The value net

> **30-second summary:** Every payment for an article is split three ways — 10% to the platform, 50% to the author, and 40% to the **earlier readers** of that same article, distributed pro-rata by how much each earlier reader paid. The mechanism is implemented in `Orders::DistributeService` and run as a background job per order.

## Why a split

On most Web3 publishing platforms, **first buyers** carry all the risk — they pay before any social proof exists, and the windfall goes to the author if the article succeeds. Quill reframes each article as a small economy that rewards the readers who **went first**.

## How the split works

The 40% early-reader share divides pro-rata by what each earlier reader paid. Tips follow the same rule — a reader who tips also counts as a buyer when later readers are rewarded — so paying more increases both your share of future pools and the size of those pools.

### Worked example

Three readers pay `100 sats` each for article X, in order:

| Order | Platform (10%) | Author (50%) | Early-reader pool (40%) | Distribution |
|-------|---------------:|-------------:|------------------------:|--------------|
| A first | 10 | 90 | 0 | No earlier readers |
| B second | 10 | 45 | 40 | A is the only earlier reader → gets all 40 |
| C third | 10 | 45 | 40 | A and B paid equal → each gets 20 |

After C, A has netted 150 sats, B 65 sats, the author 90 sats. If D then pays 200 sats, the 80-sat pool is split proportionally across A, B, C's combined 300-sat history — each gets roughly `26.67` sats.

## Rules at the edge

- **One share per reader, not per order.** A reader who both *bought* and *rewarded* the same article is one early reader — their orders fold together in `Orders::DistributeService#collect_early_readers`.
- **Mixed currencies fall back to BTC value.** When the pool and the new order span different `asset_id`s, the service weights shares by `Order#value_btc` instead of `total`. The new order joins in its own asset; only historical weights are converted.
- **Below the floor, no transfer.** A share under `Orders::DistributeService::MINIMUM_AMOUNT` (`0.00000001`) is skipped and rolls into author revenue; the author transfer is skipped if the remainder is also sub-floor.
- **References and collections pay first.** `[Reference]` articles and the parent `[Collection]` are paid out of `total` **before** the 50/40 split; the author gets what's left.
- **Payout asset is `payment.asset_id`.** Cross-asset conversion previously went through 4swap — that path is gone; multi-asset payment is now handled by MixPay, settling in each item's own asset.

## Where it lives in the codebase

The split is implemented by [`Orders::DistributeService`](../../app/services/orders/distribute_service.rb), invoked per order via [`Orders::DistributeJob`](../../app/jobs/orders/distribute_job.rb) and flushed in batches by [`Orders::BatchDistributeJob`](../../app/jobs/orders/batch_distribute_job.rb). The service is idempotent and short-circuits on `Order#completed?`.

Key symbols:

- `Order#order_type` — `:buy_article` and `:reward_article` count toward the early-reader pool; `:cite_article` does not.
- `Order#value_btc` — weights shares when the pool spans mixed currencies.
- `Order#complete!` — marks an order as distributed.
- `Orders::DistributeService::MINIMUM_AMOUNT` (`0.00000001`) — sub-floor skip threshold.
- `Orders::DistributeService#collect_early_readers` (`{ mixin_uuid => [trace_id, ...] }`) — the hash that enforces the one-share-per-reader rule.

## Settlement targets (post #1797)

Revenue routes through two kinds of Mixin identity. Per-article and per-user wallets are no longer created — provisioning a Mixin Network user now costs 0.5 USDT (`MixinBot::CREATE_USER_BILLING_INCREMENT`), and reading a wallet id must not silently spend money (#1790 §2.4).

| Recipient | Identity used | Why |
|-----------|---------------|-----|
| **Platform fee** (`quill_revenue`) | `QuillBot.api.client_id` (opponent) | Platform bot. |
| **Author revenue** | `author.mixin_uuid` (opponent) | Author's Mixin identity from OAuth. |
| **Early-reader revenue** | `buyer.mixin_uuid` (opponent) | Reader's Mixin identity (login). |
| **Reference revenue** | `reference.author.mixin_uuid` (opponent) | Cited article's author. |
| **Collection revenue** | `_order.buyer.mixin_uuid` (opponent) | Buyer's Mixin identity. |

The **source** side (`transfers.wallet_id`) is the **platform bot** for article-order transfers (`Orders::DistributeService#distributor_wallet_id = QuillBot.api.client_id`). For collection orders the source remains `payment.wallet_id` (the buyer's Mixin identity).

Existing `MixinNetworkUser` rows are kept for admin tooling — only **creation** is gated. New wallets are created explicitly via the admin Mixin Network Users console, never as a side effect of a read or publish event.

## Further reading

- [Architecture](./architecture.md) — how the distribution fits into the system.
- [Reference → Background jobs](../reference/background-jobs.md#orders) — worker queue configuration.
