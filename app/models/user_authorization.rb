# frozen_string_literal: true

# == Schema Information
#
# Table name: user_authorizations
#
#  id                                  :bigint           not null, primary key
#  access_token                        :string
#  provider(third party auth provider) :integer
#  raw(third pary user info)           :json
#  uid(third party user id)            :string
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  user_id                             :bigint
#
# Indexes
#
#  index_user_authorizations_on_provider_and_uid  (provider,uid) UNIQUE
#  index_user_authorizations_on_user_id           (user_id)
#
class UserAuthorization < ApplicationRecord
  belongs_to :user, optional: true

  enum provider: { mixin: 0 }

  validates :provider, presence: true
  validates :raw, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }
end
