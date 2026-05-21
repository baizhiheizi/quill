# frozen_string_literal: true

class ArticlePolicy < ApplicationPolicy
  def show?
    record.published? && (record.free? || record.author == user) || record.authorized?(user) || record.may_buy_by?(user)
  end

  def vote?
    user.present? && record.author != user && record.authorized?(user)
  end

  def subscribe?
    user.present? && record.authorized?(user)
  end

  def comment?
    user.present? && (record.published? || record.authorized?(user))
  end

  def update?
    user.present? && record.author == user
  end

  def create?
    user.present?
  end
end
