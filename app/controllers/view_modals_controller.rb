# frozen_string_literal: true

class ViewModalsController < ApplicationController
  def create
    type =
      if current_user.blank?
        'login'
      else
        params[:type]
      end

    case type
    when 'login'
      render :login
    when 'publish_article'
      @article = current_user.articles.find_by uuid: params[:uuid]
      return if @article.blank?

      render :publish_article
    when 'buy_article'
      @article = Article.published.find_by uuid: params[:uuid]
      return if @article.blank?

      render :buy_article
    end
  end
end
