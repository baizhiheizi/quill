# frozen_string_literal: true

class PublishedArticlesController < ApplicationController
  before_action :load_article

  def update
    if @article.published_at.present?
      if @article.may_publish?
        @article.publish!
        flash.notice = t('success_published_article')
      else
        flash.alert = t('failed_to_save')
      end
      redirect_to dashboard_articles_path(tab: :hidden)
    else
      if @article.may_publish?
        @article.publish!

        redirect_to @article, notice: t('success_published_article')
      else
        flash.now.alert = t('failed_to_save')
        render 'articles/edit', status: :unprocessable_entity
      end
    end
  end

  def destroy
    if @article.may_hide?
      @article.hide!
      flash.notice = t('success_hidden_article')
    else
      flash.alert = t('failed_to_save')
    end

    redirect_to dashboard_articles_path
  end

  private

  def load_article
    @article = current_user.articles.find_by uuid: params[:uuid]
  end
end
