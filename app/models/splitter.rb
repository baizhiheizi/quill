# frozen_string_literal: true

# == Schema Information
#
# Table name: mixin_network_users
#
#  id            :bigint           not null, primary key
#  encrypted_pin :string
#  name          :string
#  owner_type    :string
#  pin           :string
#  pin_token     :string
#  private_key   :string
#  raw           :json
#  type          :string
#  uuid          :uuid
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  owner_id      :bigint
#  session_id    :uuid
#
# Indexes
#
#  index_mixin_network_users_on_owner_type_and_owner_id  (owner_type,owner_id)
#  index_mixin_network_users_on_uuid                     (uuid) UNIQUE
#

class Splitter < MixinNetworkUser
  def collect_assets
    assets = mixin_api.assets['data']
    assets.each do |asset|
      next if asset['balance'].to_f.zero?
      next if transfers.unprocessed.where(asset_id: asset['asset_id']).present?

      transfers
        .create(
          transfer_type: :default,
          asset_id: asset['asset_id'],
          amount: asset['balance'],
          opponent_id: QuillBot.api.client_id,
          trace_id: SecureRandom.uuid,
          memo: 'assets collection'
        )
    end
  end
end
