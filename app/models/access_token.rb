# frozen_string_literal: true

# == Schema Information
#
# Table name: access_tokens
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

  after_initialize if: :new_record? do
    self.value = SecureRandom.uuid
  end

  default_scope { where(deleted_at: nil) }

  def desensitized_value
    value.first(4) + '*' * 6 + value.last(4)
  end
end
