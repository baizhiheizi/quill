Hash: manual
# app/services/orders/distribute_service.rb

`Orders::DistributeService` — the economic core that splits each completed payment into platform, author, early-reader, reference, and collection-share transfers.

- `MINIMUM_AMOUNT = 0.0000_0001` — sub-threshold transfers are skipped.
- `call(order)` branches on `order.item` type: `Article` → `distribute_article_order!`, `Collection` → `distribute_collection_order!`. Calls `order.complete!` if `order.paid?`.
- `early_orders` returns prior orders for the same item with `order_type: %i[buy_article reward_article]`, ordered by `created_at DESC`.
- `early_orders_with_the_same_currency` is true when no earlier order used a different asset.
- `collect_early_readers` groups earlier orders by `buyer.mixin_uuid` for pro-rata distribution.
- `distribute_article_order!` creates `quill_revenue` (platform), `reader_revenue` (early readers pro-rata), `reference_revenue` (cited articles), collection-share `reader_revenue`, and the residual `author_revenue` transfer. All created via `transfers.create_with(...).find_or_create_by!(trace_id: ...)` for idempotency.
- `quill_amount = total * item.platform_revenue_ratio` floored to 8 decimals.
- `distributor_wallet_id = QuillBot.api.client_id`; `revenue_asset_id` is `payment.swap_order&.fill_asset_id || payment.asset_id`.