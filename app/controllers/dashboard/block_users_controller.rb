# frozen_string_literal: true

class Dashboard::BlockUsersController < Dashboard::BaseController
  def index
    # Eager-load the avatar chain used by `shared/_avatar` (`User::AVATAR_PRELOADS`)
    # and batch the `current_user.block_user?(user)` check (action_store fires
    # one SELECT per call) into a single preloaded id set.
    @pagy, @users = pagy current_user.block_users
      .order("actions.created_at DESC")
      .includes(*User::AVATAR_PRELOADS)
    @preloaded_block_user_ids = ids_for(:block_user)
  end
end
