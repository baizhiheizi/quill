# frozen_string_literal: true

class Grover::ArticlesController < Grover::BaseController
  def poster
    @article = Article.find_by uuid: params[:article_uuid]
    @width = 640
    @height = 860
  end
end
