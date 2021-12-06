# frozen_string_literal: true

class PublishedArticlesController < ApplicationController
  before_action :load_article

  def update
    if @article.may_publish?
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

  def load_article
    @article = current_user.articles.find_by uuid: params[:uuid]
  end
end
