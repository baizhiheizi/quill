# frozen_string_literal: true

module ArticleHelper
  # "Has the viewer commenting-subscribed to this article?" — answered from
  # the primed action-id set the controller hands down
  # (`ViewerActionSets#ids_for`), so a list of rows costs one SELECT instead
  # of one per row. The set holds *every* article the viewer
  # commenting-subscribed to, so it answers the "no" case as well as the
  # "yes" case. When no controller primed the set (the single-article
  # surfaces and the subscribe/destroy turbo-stream frames), fall back to
  # the live check: one row, one query.
  def viewer_commenting_subscribed_to?(article)
    ids = @preloaded_commenting_subscribe_article_ids
    return current_user.commenting_subscribe_article?(article) if ids.nil?

    ids.include?(article.id)
  end
end
