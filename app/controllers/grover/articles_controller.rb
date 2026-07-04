# frozen_string_literal: true

class Grover::ArticlesController < Grover::BaseController
  def poster
    @article = Article.find_by uuid: params[:article_uuid]
    @width = 640
    @height = 860
  end

  def cover
    @article = Article.find_by uuid: params[:article_uuid]
    @width = 384
    @height = 384
    @cover_hue = ColorFromSeed.hue(@article&.uuid)
  end
end
