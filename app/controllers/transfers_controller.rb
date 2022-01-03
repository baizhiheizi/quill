# frozen_string_literal: true

class TransfersController < ApplicationController
  def index
    @pagy, @transfers = pagy_countless(
      Transfer
      .where(transfer_type: %w[author_revenue reader_revenue])
      .includes(:currency, source: :item)
      .order(created_at: :desc)
    )
  end

  def stats
  end
end
