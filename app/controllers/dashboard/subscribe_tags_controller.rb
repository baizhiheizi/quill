# frozen_string_literal: true

class Dashboard::SubscribeTagsController < Dashboard::BaseController
  def index
    @pagy, @tags = pagy current_user.subscribe_tags
  end
end
