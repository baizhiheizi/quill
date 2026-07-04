# frozen_string_literal: true

class Dashboard::PaymentsController < Dashboard::BaseController
  def index
    # Eager-load `:currency` for the partial at
    # `app/views/dashboard/payments/_payment.html.erb` which reads
    # `payment.currency.icon_url` and `payment.price_tag` (which itself uses
    # `currency.symbol`). Without this include, each row triggers 2 SELECTs
    # (`currencies` + `active_storage_blobs` if the icon is attached?); for a
    # payer with N payments on /dashboard/payments the action runs ~2N
    # SELECTs per page load (pagy default page size). Same N+1 family as
    # merged PRs #1802 (collections), #1815 (articles), #1829 (transfers).
    #
    # `Payment#article` / `#collection` are memo-decoded lookups
    # (`Article.find_by uuid: ...`), not AR associations, so they cannot be
    # eager-loaded here. Memoization in those methods already prevents
    # duplicate queries within a single view render.
    @pagy, @payments = pagy current_user.payments.includes(:currency).order(created_at: :desc)
  end
end
