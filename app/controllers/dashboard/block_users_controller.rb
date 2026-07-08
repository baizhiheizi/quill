# frozen_string_literal: true

class Dashboard::BlockUsersController < Dashboard::BaseController
  def index
    # Eager-load the avatar chain used by `shared/_avatar` and batch the
    # `current_user.block_user?(user)` check (action_store fires one SELECT
    # per call). See `Dashboard::BaseController#dashboard_user_field_preloads`
    # and `#preloaded_block_user_ids` for context.
    @pagy, @users = pagy current_user.block_users
      .order("actions.created_at DESC")
      .includes(dashboard_user_field_preloads)
    @preloaded_block_user_ids = preloaded_block_user_ids
  end

  private

  # Set of `User#id`s that `current_user` has blocked, in a single SELECT.
  # The partial consults this set instead of calling
  # `current_user.block_user?(user)` per row — that helper does
  # `Action.find_by(...).present?` which is 1 query per row, so a 24-row
  # page costs 24 SELECTs even after the avatar chain is eager-loaded.
  #
  # `block_user_actions` is the action_store-generated relation
  # (`has_many :block_user_actions` → `Action.where(...)`); `pluck` keeps
  # the result as a flat Array of ids so we never load the full Action
  # rows. `.to_set` makes the per-row include? check O(1).
  def preloaded_block_user_ids
    return @preloaded_block_user_ids if defined?(@preloaded_block_user_ids)
    @preloaded_block_user_ids = current_user.block_user_actions.pluck(:target_id).to_set
  end
end
