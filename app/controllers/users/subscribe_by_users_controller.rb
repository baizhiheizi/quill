# frozen_string_literal: true

module Users
  class SubscribeByUsersController < Users::BaseController
    def index
      @pagy, @users = pagy @user.subscribe_by_users.order('actions.created_at DESC')
    end
  end
end
