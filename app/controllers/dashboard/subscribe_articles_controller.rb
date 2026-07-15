# frozen_string_literal: true

class Dashboard::SubscribeArticlesController < Dashboard::BaseController
  def index
    # Eager-load `:author` plus the ActiveStorage avatar chain for the
    # partial at `app/views/dashboard/subscribe_articles/_article.html.erb`,
    # which renders `shared/avatar` with `thumb: true`. Without the
    # `UserFieldPreloads#user_field_preloads` chain each row fires ~5 extra
    # SELECTs (`authorization` + `avatar_attachment` + `blob` +
    # `variant_records` + `image_attachment.blob`). With the 50-row pagy
    # default that's ~250 extra SELECTs per index hit — same family as the
    # eager-load work already shipped for `Dashboard::BlockUsersController#index`
    # (PR #1834) and `Dashboard::SubscribeUsersController#index`.
    @pagy, @articles = pagy current_user.commenting_subscribe_articles
      .includes(author: user_field_preloads)
      .order("actions.created_at DESC")
  end
end
