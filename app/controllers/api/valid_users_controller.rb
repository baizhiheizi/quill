# frozen_string_literal: true

class API::ValidUsersController < API::BaseController
  def filter
    user = User.without_banned.find_by mixin_uuid: params[:user_id]

    render json: {
      approved: user.present? && (user.payments.completed.sum(:amount).positive? || user.articles.only_published.count.positive?)
    }
  end
end
