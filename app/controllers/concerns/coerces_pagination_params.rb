# frozen_string_literal: true

# Normalises out-of-range `?page=` input before pagy resolves it.
#
# `Pagy::CountlessPaginator` reads the raw request string
# (`resolve_page(force_integer: false)`) so `?page=0` survives as the string
# `"0"`, then splits it and hands `page: 0` to `Pagy::Offset::Countless`,
# whose `assign_and_check(page: 1)` raises `Pagy::OptionError`. Every
# non-numeric or sub-1 value trips the same assertion. See #2137.
#
# Mixed into both `ApplicationController` and `Admin::BaseController`: the two
# are separate hierarchies (`Admin::BaseController < ActionController::Base`,
# not `ApplicationController`), and both include `Pagy::Method`, so a
# before_action on one alone leaves the other half of the app exposed.
module CoercesPaginationParams
  extend ActiveSupport::Concern

  included do
    before_action :coerce_pagination_params
  end

  private

  def coerce_pagination_params
    return unless params[:page].is_a?(String)

    new_value = "1"
    return if params[:page].to_i >= 1

    params[:page] = new_value
    # Pagy reads from `request.GET` (a memoized HashWithIndifferentAccess),
    # not the controller's `params`, so both must be updated.
    request.GET["page"] = new_value
  end
end
