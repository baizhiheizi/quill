Hash: manual
# app/models/article.rb

`Article < ApplicationRecord` with `is_impressionable`, AASM, and concerns `Articles::ContentPreview`, `Articles::PosterGenerator`, `Articles::Purchasable`, `RichTextContent`.

Constants:
- `SUPPORTED_ASSETS = Settings.supported_assets || [Currency::BTC_ASSET_ID]`
- `AUTHOR_REVENUE_RATIO_DEFAULT = 0.5`
- `READERS_REVENUE_RATIO_DEFAULT = 0.4`
- `PLATFORM_REVENUE_RATIO_DEFAULT = 0.1`

Schema columns include: `author_revenue_ratio: 0.5`, `readers_revenue_ratio: 0.4`, `platform_revenue_ratio: 0.1`, `collection_revenue_ratio: 0.0`, `references_revenue_ratio: 0.0`, `free_content_ratio: 0.1`, `price`, `state`, `intro`, `title`, `uuid`, `asset_id`, `author_id`, `collection_id`, `published_at`, `revenue_btc`, `revenue_usd`, counter caches (`orders_count`, `comments_count`, `tags_count`, `upvotes_count`, `downvotes_count`).