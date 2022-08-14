# frozen_string_literal: true

class Dashboard::DeletedArticlesController < Dashboard::BaseController
  before_action :load_article

  def new
  end

  def update
    return if @article.blank?

    @article.destroy!
  end

  private

  def load_article
    @article = current_user.articles.drafted.find_by uuid: params[:uuid]
  end
end
