# frozen_string_literal: true

class Dashboard::TransfersController < Dashboard::BaseController
  def index
    @tab = params[:tab] || 'author'

    transfers =
      case @tab
      when 'author'
        current_user.author_revenue_transfers
      when 'reader'
        current_user.reader_revenue_transfers
      end

    @pagy, @transfers = pagy transfers.order(created_at: :desc)
  end

  def stats
    @role = params[:role] || 'author'
  end
end
