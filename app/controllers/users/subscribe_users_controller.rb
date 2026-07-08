# frozen_string_literal: true

module Users
  class SubscribeUsersController < Users::BaseController
    # Eager-load the avatar chain (see
    # `Users::BaseController#users_user_field_preloads`) and batch the
    # per-row `current_user.subscribe_user?(user)` action_store check via
    # the shared `Users::BaseController#preloaded_subscribe_user_ids`
    # helper.
    def index
      @preloaded_subscribe_user_ids = preloaded_subscribe_user_ids
      @pagy, @users = pagy @user.subscribe_users.order("actions.created_at DESC")
        .includes(users_user_field_preloads)
    end
  end
end
