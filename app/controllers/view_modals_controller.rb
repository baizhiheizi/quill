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
      return if @article.blank? || @article.authorized?(current_user)

      render :buy_article
    when 'reward_article'
      @article = Article.published.find_by uuid: params[:uuid]
      return unless @article&.authorized?(current_user)

      render :reward_article
    when 'generate_access_token'
      render :generate_access_token
    when 'confirm'
      render :confirm
    when 'share_article'
      @article = Article.published.find_by uuid: params[:uuid]
      render :share_article
    end
  end
end
