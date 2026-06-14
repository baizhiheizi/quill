size:7030
# Orders::DistributeService summary

Implements the 10/50/40 value-net split for paid orders.

- `MINIMUM_AMOUNT = 0.0000_0001` — under this the transfer is skipped.
- `self.call(order)` / `#call` — entry point; no-op if `@order.completed?`; dispatches to `distribute_article_order!` (when `item.is_a?(Article)`) or `distribute_collection_order!` (when `Collection`).
- Article path computes:
  1. `quill_amount = total * platform_revenue_ratio` (10%) → transfer to Quill platform wallet
  2. Reader pool = `total * item.readers_revenue_ratio` (40%), split pro-rata across `early_orders` keyed by buyer
  3. Reference revenue: a `Base64`-encoded `CITE` memo per citing article
  4. Collection revenue: average share of `total * collection_revenue_ratio` across prior `buy_collection` orders
  5. Author residual = `total - readers - quill - references - collection`
- Uses `MixinBot::Utils.unique_uuid(trace_id, opponent_id)` to derive deterministic `trace_id`s for `find_or_create_by!` idempotency.
- `early_orders_with_the_same_currency` switches share calculation between native `total` and BTC-denominated `value_btc`.
