# frozen_string_literal: true

class SubscribeArticlesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_article

  def new
  end

  def create
    current_user.create_action :commenting_subscribe, target: @article
  end

  def destroy
    current_user.destroy_action :commenting_subscribe, target: @article
  end

  private

  def load_article
    @article = Article.only_published.find_by uuid: params[:uuid]
  end
end
