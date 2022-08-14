# frozen_string_literal: true

class Dashboard::SubscribeUsersController < Dashboard::BaseController
  def index
    @pagy, @users = pagy current_user.subscribe_users.order('actions.created_at DESC')
  end
end
