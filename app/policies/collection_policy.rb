# frozen_string_literal: true

class CollectionPolicy < ApplicationPolicy
  def show?
    record.published? || record.authorized?(user) || record.author == user
  end

  def update?
    user.present? && record.author == user
  end
end
