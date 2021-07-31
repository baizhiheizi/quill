# frozen_string_literal: true

class ArticlesController < ApplicationController
  def index
    @articles = Article.only_published.order(created_at: :desc).first(20)
    respond_to do |format|
      format.html
      format.rss do
        render layout: false
      end
    end
  end

  def show
    article = Article.only_published.find_by uuid: params[:uuid]
    return if article.blank?

    @page_title = "#{article.title} - #{article.author.name}"
    @page_description = article.intro
  end
end
