# frozen_string_literal: true

class TransfersController < ApplicationController
  def index
    @pagy, @transfers = pagy_countless Transfer.where(transfer_type: %w[author_revenue reader_revenue]).order(created_at: :desc)
  end
end
