# frozen_string_literal: true

class Dashboard::PublishedArticlesController < Dashboard::BaseController
  before_action :load_article

  def new
  end

  def update
    if @article.published_at.present?
      @article.publish! if @article.may_publish?
    elsif @article.may_publish?
      redirect_to @article, notice: t('success_published_article') if @article.publish!
    end
  end

  def destroy
    @article.hide! if @article.may_hide?
  end

  private

  def load_article
    @article = current_user.articles.find_by uuid: params[:uuid]
  end
end
