# frozen_string_literal: true

class Dashboard::DeletedArticlesController < Dashboard::BaseController
  before_action :load_article

  def new
    render_404_and_return if @article.blank?
  end

  def update
    return render_404_and_return if @article.blank?

    authorize @article, :destroy?
    @article.destroy!
  end

  private

  def load_article
    @article = current_user.articles.drafted.find_by uuid: params[:uuid]
  end

  # When the article is missing or not owned by the current user, short-circuit
  # with a 404 instead of falling through to render the template with
  # @article = nil (which would crash on `dom_id(@article)` /
  # `dashboard_deleted_article_path(nil)`).
  def render_404_and_return
    head :not_found
    nil
  end
end
