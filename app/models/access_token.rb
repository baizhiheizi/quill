# frozen_string_literal: true

# == Schema Information
#
# Table name: access_tokens
#
#  id           :integer          not null, primary key
#  user_id      :integer
#  value        :uuid
#  memo         :string
#  last_request :jsonb
#  deleted_at   :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
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
    value.first(4) + ('*' * 6) + value.last(4)
  end
end
