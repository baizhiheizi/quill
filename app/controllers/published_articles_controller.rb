# frozen_string_literal: true

class PublishedArticlesController < ApplicationController
  before_action :load_article

  def update
    if @article.published_at?
      @article.publish! if @article.may_publish?

      redirect_to @article, notice: t('success_published_article')
    elsif @article.published_at.blank?
      @article.update article_params
      @article.publish! if @article.may_publish?

      redirect_to @article, notice: t('success_published_article')
    else
      flash.now.alert = t('failed_to_save')
      render 'articles/publish', status: :unprocessable_entity
    end
  end

  def destroy
  end

  private

  def article_params
    params.require(:article).permit(:price, :asset_id, :intro)
  end

  def load_article
    @article = current_user.articles.find_by uuid: params[:uuid]
  end
end
