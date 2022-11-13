# frozen_string_literal: true

# == Schema Information
#
# Table name: user_authorizations
#
#  id                                  :bigint           not null, primary key
#  access_token                        :string
#  provider(third party auth provider) :integer
#  public_key                          :string
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
  store_accessor :raw, %i[phone key contract avatar_url name biography]

  belongs_to :user, optional: true

  enum provider: { mixin: 0, fennec: 1, mvm_eth: 2 }

  validates :provider, presence: true
  validates :raw, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }

  def mixin_api
    return unless provider == 'mvm_eth'
    return if key.blank?

    @mixin_api ||= MixinBot::API.new(
      client_id: key['client_id'],
      private_key: key['private_key'],
      session_id: key['session_id']
    )
  end
end
