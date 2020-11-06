# frozen_string_literal: true

class ArticlesController < ApplicationController
  def show
    article = Article.only_published.find_by uuid: params[:id]
    return if article.blank?

    @page_title = "#{article.title} - #{article.author.name}"
    @page_description = article.intro
  end
end
