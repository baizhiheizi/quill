# frozen_string_literal: true

# == Schema Information
#
# Table name: user_authorizations
#
#  id           :integer          not null, primary key
#  user_id      :integer
#  provider     :integer
#  uid          :string
#  access_token :string
#  raw          :json
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_user_authorizations_on_provider_and_uid  (provider,uid) UNIQUE
#  index_user_authorizations_on_user_id           (user_id)
#

class UserAuthorization < ApplicationRecord
  MIXIN_AUTHORIZATION_SCOPE = "PROFILE:READ#{Settings.whitelist&.enable&.presence && '+PHONE:READ'}".freeze

  store_accessor :raw, :phone

  belongs_to :user, optional: true

  enum provider: { mixin: 0 }

  validates :provider, presence: true
  validates :raw, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }
end
