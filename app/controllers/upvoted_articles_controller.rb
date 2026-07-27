# frozen_string_literal: true

class UpvotedArticlesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_article

  def update
    return if @article.blank?
    return if @article.author == current_user

    authorize @article, :vote?

    @article.with_lock do
      current_user.create_action :upvote, target: @article
      current_user.destroy_action :downvote, target: @article
    end

    @article.reload

    PostHog.capture(
      distinct_id: current_user.posthog_distinct_id,
      event: "article_upvoted",
      properties: {
        article_uuid: @article.uuid,
        upvotes_count: @article.upvotes_count
      }
    )
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
