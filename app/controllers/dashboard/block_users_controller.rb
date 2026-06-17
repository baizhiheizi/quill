# frozen_string_literal: true

class Dashboard::BlockUsersController < Dashboard::BaseController
  def index
    @pagy, @users = pagy current_user.block_users.order("actions.created_at DESC")
  end
end
