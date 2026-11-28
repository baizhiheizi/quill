# frozen_string_literal: true

class Dashboard::SubscribeTagsController < Dashboard::BaseController
  def index
    @pagy, @tags = pagy current_user.subscribe_tags.order("actions.created_at DESC")
    # Batch the per-row `subscribe_tag?` check the button partial makes
    # (action_store fires one SELECT per call) into a single preloaded id
    # set, the same shape `Dashboard::SubscribeUsersController` uses.
    @preloaded_subscribe_tag_ids = ids_for(:subscribe_tag)
  end
end
