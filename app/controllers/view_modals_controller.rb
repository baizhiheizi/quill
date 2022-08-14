# frozen_string_literal: true

class ViewModalsController < ApplicationController
  def create
    type = params[:type]

    case type
    when 'publish_article'
      @article = current_user.articles.find_by uuid: params[:uuid]
      return if @article.blank?
    end

    render type
  end
end
