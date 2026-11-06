# frozen_string_literal: true

class CollectionPolicy < ApplicationPolicy
  def purchase?
    user.present? && !record.authorized?(user)
  end
end
