# frozen_string_literal: true

# Normalises out-of-range `?page=` input before pagy resolves it.
#
# `Pagy::CountlessPaginator` reads the raw request string
# (`resolve_page(force_integer: false)`) so `?page=0` survives as the string
# `"0"`, then splits it and hands `page: 0` to `Pagy::Offset::Countless`,
# whose `assign_and_check(page: 1)` raises `Pagy::OptionError`. Every
# non-numeric or sub-1 value trips the same assertion. See #2137.
#
# The upper bound matters just as much: a huge `?page=` is a perfectly valid
# integer to pagy, but the derived OFFSET (`limit * (page - 1)`) then
# overflows a Postgres bigint and the query fails with
# `PG::NumericValueOutOfRange` -> HTTP 500.
#
# Mixed into both `ApplicationController` and `Admin::BaseController`: the two
# are separate hierarchies (`Admin::BaseController < ActionController::Base`,
# not `ApplicationController`), and both include `Pagy::Method`, so a
# before_action on one alone leaves the other half of the app exposed.
module CoercesPaginationParams
  extend ActiveSupport::Concern

  # Keeps `limit * (page - 1)` inside a Postgres bigint and bounds the OFFSET
  # so a huge page number cannot turn into a 500 or a pathological scan.
  MAX_PAGE = 10_000

  included do
    before_action :coerce_pagination_params
  end

  private

  def coerce_pagination_params
    key = page_key
    return unless params[key].is_a?(String)

    new_value = "1"
    page = params[key].to_i
    return if page.between?(1, MAX_PAGE)

    params[key] = new_value
    # Pagy reads the page from `request.GET` (a memoized
    # HashWithIndifferentAccess), not from the controller's `params`, so the
    # `request.GET` write is the one that decides which page pagy renders.
    # The `params` write only keeps the two in sync for application code.
    request.GET[key] = new_value
  end

  # Pagy resolves the page parameter from its own configuration
  # (`@options[:page_key] || DEFAULT[:page_key]`), so the concern has to use
  # the same key instead of hardcoding "page".
  def page_key
    Pagy::OPTIONS[:page_key] || Pagy::DEFAULT[:page_key]
  end
end
