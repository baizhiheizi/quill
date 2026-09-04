# frozen_string_literal: true

class Dashboard::SubscribeUsersController < Dashboard::BaseController
  def index
    # Eager-load the avatar chain used by `shared/_avatar` (`User::AVATAR_PRELOADS`)
    # and batch the `current_user.subscribe_user?(user)` check (action_store
    # fires one SELECT per call) into a single preloaded id set.
    @pagy, @users = pagy current_user.subscribe_users
      .order("actions.created_at DESC")
      .includes(*User::AVATAR_PRELOADS)
    @preloaded_subscribe_user_ids = ids_for(:subscribe_user)
  end
end
