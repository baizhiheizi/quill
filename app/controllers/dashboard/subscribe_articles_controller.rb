# frozen_string_literal: true

class Dashboard::SubscribeArticlesController < Dashboard::BaseController
  def index
    @pagy, @articles = pagy current_user.commenting_subscribe_articles.order('actions.created_at DESC')
  end
end
