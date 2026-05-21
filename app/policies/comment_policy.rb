# frozen_string_literal: true

class CommentPolicy < ApplicationPolicy
  def create?
    return false if user.blank?
    return false unless record.is_a?(Article)

    record.published? || record.authorized?(user)
  end

  def vote?
    return false if user.blank?
    return false if record.author == user

    commentable = record.commentable
    return false unless commentable.is_a?(Article)

    ArticlePolicy.new(user, commentable).vote?
  end
end
