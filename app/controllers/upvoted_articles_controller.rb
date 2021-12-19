# frozen_string_literal: true

class UpvotedArticlesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_article

  def update
    return if @article.blank?
    return if @article.author == current_user
    return unless @article.authorized? current_user

    @article.with_lock do
      current_user.create_action :upvote, target: @article
      current_user.destroy_action :downvote, target: @article
    end

    @article.reload
  end

  def destroy
    current_user.destroy_action :upvote, target: @article

    @article.reload
  end

  private

  def load_article
    @article = Article.find_by uuid: params[:uuid]
  end
end
