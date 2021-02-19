# frozen_string_literal: true

# == Schema Information
#
# Table name: user_access_tokens
#
#  id         :bigint           not null, primary key
#  memo       :string           not null
#  value      :uuid
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint
#
# Indexes
#
#  index_user_access_tokens_on_user_id  (user_id)
#  index_user_access_tokens_on_value    (value) UNIQUE
#
class UserAccessToken < ApplicationRecord
  belongs_to :user

  validates :value, presence: true, uniqueness: true
  validates :memo, presence: true

  after_initialize if: :new_record? do
    self.value = SecureRandom.uuid
  end

  def desensitized_value
    value.first(4) + '*' * 6 + value.last(4)
  end
end
