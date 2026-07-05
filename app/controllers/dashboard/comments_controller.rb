# frozen_string_literal: true

class Dashboard::CommentsController < Dashboard::BaseController
  before_action :load_article

  def index
    comments =
      if @article.present?
        @article.comments
      else
        current_user.comments
      end

    # Eager-load associations consumed by the rendered partial at
    # `app/views/dashboard/comments/_comment.html.erb`:
    #   - `:commentable`     → `comment.commentable.title` in the link
    #   - `:author`          → if the partial ever renders the comment author
    #   - `commentable: :author` → `comment.commentable.author` in
    #     `user_article_path(comment.commentable.author, comment.commentable.uuid, ...)`
    #
    # Without the nested preload, `:commentable` is eager-loaded but each row
    # then triggers one SELECT on `users` for `commentable.author`. For a
    # user with N comments the action runs ~3N SELECTs per page load
    # (1 + 1 + 1 per row); the nested include drops it to ~3 SELECTs total
    # regardless of page size. Same N+1 family as merged PRs #1802
    # (collections), #1815 (articles), #1829 (transfers), #1830 (payments).
    @pagy, @comments = pagy comments.includes(:commentable, :author, commentable: :author).order(created_at: :desc)
  end

  private

  def load_article
    @article = current_user.articles.find_by uuid: params[:article_uuid]
  end
end
