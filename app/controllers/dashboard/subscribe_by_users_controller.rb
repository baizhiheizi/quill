# frozen_string_literal: true

class Dashboard::SubscribeByUsersController < Dashboard::BaseController
  def index
    @pagy, @users = pagy current_user.subscribe_by_users
  end
end
