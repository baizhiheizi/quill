# frozen_string_literal: true

module Users
  class SubscribeUsersController < Users::BaseController
    def index
      @pagy, @users = pagy @user.subscribe_users.order('actions.created_at DESC')
    end
  end
end
