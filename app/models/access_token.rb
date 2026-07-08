# frozen_string_literal: true

# == Schema Information
#
# Table name: access_tokens
# Database name: primary
#
#  id           :bigint           not null, primary key
#  deleted_at   :datetime
#  last_request :jsonb
#  memo         :string
#  value        :uuid
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint
#
# Indexes
#
#  index_access_tokens_on_user_id  (user_id)
#  index_access_tokens_on_value    (value) UNIQUE
#

class AccessToken < ApplicationRecord
  include SoftDeletable

  store :last_request, accessors: %i[ip url method at], prefix: true

  belongs_to :user

  validates :value, presence: true, uniqueness: true
  validates :memo, presence: true
  validate :within_per_user_limit, on: :create

  after_initialize if: :new_record? do
    self.value = SecureRandom.uuid
  end

  scope :kept, -> { without_deleted }

  # Defense-in-depth cap behind the `access_tokens/user` throttle. Limits how
  # many active (non-soft-deleted) tokens a single user can hold — long-lived
  # credentials that otherwise have no mint-rate bound.
  def self.per_user_limit
    20
  end

  def desensitized_value
    value.first(4) + ("*" * 6) + value.last(4)
  end

  private

  def within_per_user_limit
    return if user_id.blank?

    return if user.access_tokens.kept.count < self.class.per_user_limit

    errors.add(:base, :token_limit_exceeded, limit: self.class.per_user_limit)
  end
end
