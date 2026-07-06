# frozen_string_literal: true

class Dashboard::CommentsController < Dashboard::BaseController
  before_action :load_article

  def index
    comments =
      if @article.present?
        @article.comments.includes(:author)
      else
        current_user.comments.includes(commentable: :author)
      end

    @pagy, @comments = pagy comments.order(created_at: :desc)
  end

  private

  def load_article
    @article = current_user.articles.find_by uuid: params[:article_uuid]
  end
end
