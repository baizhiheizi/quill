# frozen_string_literal: true

class CommentPolicy < ApplicationPolicy
  def vote?
    return false if user.blank?
    return false if record.author == user

    commentable = record.commentable
    return false unless commentable.is_a?(Article)

    ArticlePolicy.new(user, commentable).vote?
  end
end
