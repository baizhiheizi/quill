# frozen_string_literal: true

module Users
  class SubscribeByUsersController < Users::BaseController
    # Eager-load the avatar chain (`User::AVATAR_PRELOADS`, used by
    # `shared/_avatar`) and batch the per-row
    # `current_user.subscribe_user?(user)` action_store check via
    # `ViewerActionSets#ids_for`.
    def index
      @preloaded_subscribe_user_ids = ids_for(:subscribe_user)
      @pagy, @users = pagy @user.subscribe_by_users.order("actions.created_at DESC")
        .includes(*User::AVATAR_PRELOADS)
    end
  end
end
