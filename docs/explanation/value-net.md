# The value net

> **30-second summary:** Every payment for an article is split three ways — 10% to the platform, 50% to the author, and 40% to the **earlier readers** of that same article, distributed pro-rata by how much each earlier reader paid. The mechanism is implemented in `Orders::DistributeService` and run as a background job per order.

## The problem with traditional publishing

On most Web3 publishing platforms the **first buyers** of an article take the most risk: they pay before there is any social proof that the content is valuable. If the article succeeds, the windfall goes to the author; the early backers are forgotten.

Quill reframes the article as a small economy. Each new payment not only rewards the author but also compensates the readers who **went first**, so the value created by the article is shared with the people whose early conviction unlocked it.

## How the split works

For every order on an article:

| Recipient | Share |
|-----------|-------|
| **Platform** handling fee | 10% |
| **Article author** | 50% |
| **Early readers** (all previous readers of this article) | 40% |

The 40% early-reader share is divided proportionally to what each earlier reader originally paid. Rewards behave the same way: a reader who tips an article also counts as a buyer when later readers are rewarded.

### Worked example

Imagine three readers, A, B, and C, each paying `100 sats` for article X in order.

| Order | Total paid | Platform 10% | Author 50% | Early-reader pool 40% | Distribution |
|-------|-----------:|-------------:|-----------:|----------------------:|--------------|
| A first | 100 | 10 | 90 | 0 | A is the only reader → no one to reward |
| B second | 100 | 10 | 45 | 40 | A is the sole earlier reader → A gets all 40 |
| C third | 100 | 10 | 45 | 40 | A and B are earlier readers (paid equal) → each gets 20 |

After C, A has earned `90 + 40 + 20 = 150` sats net, B has earned `0 + 45 + 20 = 65` sats, and the author has earned `45 + 45 = 90` sats for two sales of equal price.

If a fourth reader D pays `200` sats, the early-reader pool becomes `80` sats, split by historical payment (A: 100, B: 100, C: 100 → total 300), so each of A, B, C gets `80 × 100/300 ≈ 26.67` sats.

### Why pricing matters

A reader who pays more for an article (either through a higher price or a reward) increases both:

1. their **share** of every future early-reader pool for that article, and
2. the **size** of future pools, because future readers' payments feed the same mechanism.

This is the lever that turns passive reading into active stake-holding in the article's success.

## Where it lives in the codebase

The split is implemented by [`Orders::DistributeService`](../../app/services/orders/distribute_service.rb) and invoked per order via [`Orders::DistributeJob`](../../app/jobs/orders/distribute_job.rb). Batches of pending orders are flushed by [`Orders::BatchDistributeJob`](../../app/jobs/orders/batch_distribute_job.rb).

Key terms to look up in the code:

- `Order#order_type` — `:buy_article`, `:reward_article`, `:cite_article`. Only the first two count toward the early-reader pool.
- `Order#complete!` — marks the order as distributed so it cannot be paid twice.
- `Order::MINIMUM_AMOUNT` — the smallest payment the service will process.

## Further reading

- [README](../../README.md) for the user-facing description.
- [Architecture](./architecture.md) for how the distribution fits into the rest of the system.
- [Reference → Background jobs](../reference/background-jobs.md#orders) for the worker queue configuration.