# frozen_string_literal: true

class CommentPolicy < ApplicationPolicy
  def create?
    return false if user.blank?
    return false unless record.is_a?(Article)

    record.published? || record.authorized?(user)
  end
end
