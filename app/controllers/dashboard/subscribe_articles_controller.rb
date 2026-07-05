# frozen_string_literal: true

class Dashboard::SubscribeArticlesController < Dashboard::BaseController
  def index
    # Eager-load `:author` for the partial at
    # `app/views/dashboard/subscribe_articles/_article.html.erb`, which reads
    # `article.author` twice (once in `user_article_path`, once in
    # `shared/avatar`). Without this include each row triggers a SELECT on
    # `users`; for a user subscribed to N articles' comments the action runs
    # ~2N SELECTs per page load (pagy default page size).
    @pagy, @articles = pagy current_user.commenting_subscribe_articles.includes(:author).order("actions.created_at DESC")
  end
end
