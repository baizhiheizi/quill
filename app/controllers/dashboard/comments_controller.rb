# frozen_string_literal: true

class Dashboard::CommentsController < Dashboard::BaseController
  before_action :load_article

  def index
    # Eager-load `:author` plus the ActiveStorage avatar chain for the
    # partial at `app/views/dashboard/comments/_article_comment.html.erb`,
    # which renders `shared/avatar` with `thumb: true`. Without the
    # `dashboard_user_field_preloads` chain each row fires ~5 extra SELECTs
    # (`authorization` + `avatar_attachment` + `blob` + `variant_records` +
    # `image_attachment.blob`). The second branch also eager-loads
    # `commentable.author` for the partial's `comment.commentable.title` →
    # `user_article_path(commentable.author, ...)` link, which walks the
    # polymorphic `commentable` (`Article` / `Collection`) plus its
    # `author` User row. Same family of gaps closed in PRs #1802/#1815/
    # #1829/#1830/#1833/#1834/#1843 for the other dashboard surfaces.
    comments =
      if @article.present?
        @article.comments.includes(author: dashboard_user_field_preloads)
      else
        current_user.comments.includes(author: dashboard_user_field_preloads, commentable: :author)
      end

    @pagy, @comments = pagy comments.order(created_at: :desc)
  end

  private

  def load_article
    @article = current_user.articles.find_by uuid: params[:article_uuid]
  end
end
