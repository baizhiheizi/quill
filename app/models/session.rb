# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id         :bigint           not null, primary key
#  info       :json
#  uuid       :uuid
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint
#
# Indexes
#
#  index_sessions_on_user_id  (user_id)
#  index_sessions_on_uuid     (uuid) UNIQUE
#
class Session < ApplicationRecord
  belongs_to :user

  before_validation :setup_attributes, on: :create

  validates :uuid, presence: true
  validates :info, presence: true

  private

  def setup_attributes
    self.uuid ||= SecureRandom.uuid
  end
end
