# frozen_string_literal: true

class Dashboard::SubscribeUsersController < Dashboard::BaseController
  def index
    # Eager-load the avatar chain used by `shared/_avatar` and batch the
    # `current_user.subscribe_user?(user)` check (action_store fires one
    # SELECT per call). See `Dashboard::BaseController#dashboard_user_field_preloads`
    # and `#preloaded_subscribe_user_ids` for context.
    @pagy, @users = pagy current_user.subscribe_users
      .order("actions.created_at DESC")
      .includes(dashboard_user_field_preloads)
    @preloaded_subscribe_user_ids = preloaded_subscribe_user_ids
  end

  private

  # Set of `User#id`s that `current_user` is subscribed to, in a single
  # SELECT. The partial consults this set instead of calling
  # `current_user.subscribe_user?(user)` per row — same N+1 reasoning as
  # `Dashboard::BlockUsersController#preloaded_block_user_ids`.
  def preloaded_subscribe_user_ids
    return @preloaded_subscribe_user_ids if defined?(@preloaded_subscribe_user_ids)
    @preloaded_subscribe_user_ids = current_user.subscribe_user_actions.pluck(:target_id).to_set
  end
end
