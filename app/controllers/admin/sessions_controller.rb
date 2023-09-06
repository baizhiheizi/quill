# frozen_string_literal: true

class Admin::SessionsController < Admin::BaseController
  def index
    sessions = Session.all
    sessions = sessions.where(user_id: params[:user_id]) if params[:user_id].present?

    @order_by = params[:order_by] || 'created_at_desc'
    case @order_by
    when 'created_at_desc'
      sessions.order(created_at: :desc)
    when 'created_at_asc'
      sessions.order(created_at: :asc)
    end

    @pagy, @sessions = pagy(sessions.order(created_at: :desc))
  end
end
