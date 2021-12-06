# frozen_string_literal: true

class TagsController < ApplicationController
  def index
    q = { name_i_cont: params[:query].to_s.strip }
    @pagy, @tags = pagy Tag.ransack(q.merge(m: 'or')).result

    respond_to do |format|
      format.html
      format.json do
        render json: @tags.pluck(:name)
      end
    end
  end

  def show
    tag = Tag.find_by id: params[:id]
    return if tag.blank?

    @page_title = "##{tag.name} 话题文章"
    @page_description = "##{tag.name} 话题下有 #{tag.articles_count} 篇文章"
  end
end
