# frozen_string_literal: true

class TransfersController < ApplicationController
  def index
    @pagy, @transfers = pagy_countless Transfer.order(created_at: :desc)
  end
end
