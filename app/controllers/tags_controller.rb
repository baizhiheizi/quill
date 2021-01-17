# frozen_string_literal: true

class TagsController < ApplicationController
  def show
    tag = Tag.find_by id: params[:id]
    return if tag.blank?

    @page_title = "##{tag.name} 话题文章"
    @page_description = "##{tag.name} 话题下有 #{tag.articles_count} 篇文章"
  end
end
