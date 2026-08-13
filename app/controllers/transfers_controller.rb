# frozen_string_literal: true

class TransfersController < ApplicationController
  def index
    # Eager-load associations consumed by the rendered partial
    # `app/views/transfers/_transfer.html.erb`:
    #   - `:currency` → `transfer.currency.icon_url`, `transfer.price_tag`
    #   - `source: { item: :author }` → `transfer.source.item` (polymorphic
    #     Order → Article/Collection) and, for the Article branch,
    #     `transfer.source.item.author` (used by `user_article_path`).
    #     The nested polymorphic preload fires one SELECT per `item_type`
    #     instead of one SELECT per row.
    #
    # Without the `source: { item: :author }` includes, every Article-source
    # row fires 1 extra SELECT to load the item's author. For a page of N
    # transfers where most rows point to Articles (the common case), that
    # is N redundant SELECTs per page load.
    @pagy, @transfers = pagy(:countless, Transfer
      .where(transfer_type: %w[author_revenue reader_revenue])
      .includes(:currency, source: { item: :author })
      .order(created_at: :desc)
    )
  end

  def stats
  end
end
