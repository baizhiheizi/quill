# frozen_string_literal: true

class API::ValidUsersController < API::BaseController
  def filter
    user = User.without_banned.find_by mixin_uuid: params[:user_id]

    approved =
      if user.blank?
        false
      elsif params[:type] == 'recent'
        user.payments.where(state: %i[paid completed], created_at: 1.week.ago...).sum(:amount).positive? || user.articles.only_published.where(published_at: 1.week.ago...).count.positive?
      else
        user.payments.where(state: %i[paid completed]).sum(:amount).positive? || user.articles.only_published.count.positive?
      end

    render json: {
      approved: approved
    }
  end
end
