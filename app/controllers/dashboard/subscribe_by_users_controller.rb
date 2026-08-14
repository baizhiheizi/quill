# frozen_string_literal: true

class Dashboard::SubscribeByUsersController < Dashboard::BaseController
  # Eager-load the avatar chain used by `shared/_avatar` and batch the
  # `current_user.subscribe_user?(user)` check (action_store fires one
  # SELECT per call). Mirrors `Dashboard::SubscribeUsersController#index`,
  # which already ships with both preloads; the inverse relationship was
  # missed in the original perf-improver pass.
  def index
    @preloaded_subscribe_user_ids = preloaded_subscribe_user_ids
    @pagy, @users = pagy current_user.subscribe_by_users
      .order("actions.created_at DESC")
      .includes(user_field_preloads)
  end

  private

  # Set of `User#id`s that `current_user` is subscribed to, in a single
  # SELECT. The partial consults this set instead of calling
  # `current_user.subscribe_user?(user)` per row.
  def preloaded_subscribe_user_ids
    return @preloaded_subscribe_user_ids if defined?(@preloaded_subscribe_user_ids)
    @preloaded_subscribe_user_ids = current_user.subscribe_user_actions.pluck(:target_id).to_set
  end
end