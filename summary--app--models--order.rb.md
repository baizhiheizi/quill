Hash: manual
# app/models/order.rb

`Order < ApplicationRecord` with `AASM` and `Orders::Distributable` concerns.

Constants:
- `PLATFORM_RATIO = 0.1`

Associations:
- `buyer` / `seller` (User)
- `citer` polymorphic, optional
- `item` polymorphic (Article / Collection) with `counter_cache: true`
- `payment` via `trace_id` / `primary_key: trace_id`
- `currency` via `asset_id` / `primary_key: asset_id`
- `kernel_output` via `trace_id` / `request_id`, optional
- `transfers` polymorphic, `dependent: :restrict_with_exception`

Validations:
- `order_type` uniqueness scoped for `buy_article?` / `buy_collection?`
- `total` presence; `trace_id` uniqueness; `ensure_total_sufficient` on create

Enum `order_type`: `buy_article: 0`, `reward_article: 1`, `cite_article: 2`, `buy_collection: 3`

Callbacks:
- `before_validation :setup_attributes, on: :create`
- `after_create :subscribe_comments_for_buyer, :broadcast_to_views`
- `after_create_commit :update_cache_async, :notify_async, :distribute_async`
- `before_destroy :destroy_notifications`

`broadcast_to_article_views` issues Turbo Stream `broadcast_replace_later_to` / `broadcast_remove_to` for the buyer's per-user channel.