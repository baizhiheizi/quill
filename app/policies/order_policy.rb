# frozen_string_literal: true

class OrderPolicy < ApplicationPolicy
  def show?
    user.present? && (record.buyer == user || record.item.try(:author) == user)
  end
end
