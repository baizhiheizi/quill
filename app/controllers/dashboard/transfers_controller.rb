# frozen_string_literal: true

class Dashboard::TransfersController < Dashboard::BaseController
  def index
    @tab = params[:tab] || "author"

    transfers =
      case @tab
      when "author"
        current_user.author_revenue_transfers
      when "reader"
        current_user.reader_revenue_transfers
      end

    # Eager-load associations consumed by the rendered partial
    # `app/views/dashboard/transfers/_transfer.html.erb`:
    #   - `:currency` → `transfer.currency.icon_url`, `transfer.price_tag`
    #   - `source: { item: :author }` → `transfer.source.item` (polymorphic
    #     Order → Article/Collection) and `transfer.source.item.author`
    #     (Article branch only). The nested polymorphic preload fires one
    #     SELECT per `item_type` instead of one SELECT per row.
    #
    # Without these includes each row triggers ~4 SELECTs (currency +
    # polymorphic source + polymorphic item + author for Article rows). For
    # an author/reader with N transfers on /dashboard/transfers, the action
    # runs ~4N SELECTs per page load (pagy default page size).
    @pagy, @transfers = pagy transfers.includes(:currency, source: { item: :author }).order(created_at: :desc)
  end

  def stats
    @role = params[:role] || "author"
  end
end
