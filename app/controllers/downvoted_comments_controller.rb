# frozen_string_literal: true

class DownvotedCommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_comment

  def update
    return if @comment.author == current_user
    return unless @comment.commentable.authorized? current_user

    @comment.with_lock do
      current_user.create_action :downvote, target: @comment
      current_user.destroy_action :upvote, target: @comment
    end
  end

  def destroy
    current_user.destroy_action :downvote, target: @comment
  end

  private

  def load_comment
    @comment = Comment.without_deleted.find params[:id]
  end
end
