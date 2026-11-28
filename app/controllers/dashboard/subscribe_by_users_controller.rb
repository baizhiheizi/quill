# frozen_string_literal: true

class Dashboard::SubscribeByUsersController < Dashboard::BaseController
  def index
    # Eager-load the avatar chain used by `shared/_avatar`
    # (`User::AVATAR_PRELOADS`) and batch the
    # `current_user.subscribe_user?(user)` check (action_store fires one
    # SELECT per call) into a single preloaded id set — the same treatment
    # `Dashboard::SubscribeUsersController#index` already carries.
    @pagy, @users = pagy current_user.subscribe_by_users.order("actions.created_at DESC")
      .includes(*User::AVATAR_PRELOADS)
    @preloaded_subscribe_user_ids = ids_for(:subscribe_user)
  end
end
