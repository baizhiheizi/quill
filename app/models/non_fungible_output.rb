# frozen_string_literal: true

# == Schema Information
#
# Table name: non_fungible_outputs
#
#  id         :bigint           not null, primary key
#  raw        :jsonb
#  state      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  token_id   :uuid
#  user_id    :uuid
#
# Indexes
#
#  index_non_fungible_outputs_on_token_id  (token_id)
#  index_non_fungible_outputs_on_user_id   (user_id)
#
class NonFungibleOutput < ApplicationRecord
  store_accessor :raw, %i[output_id]

  belongs_to :user, primary_key: :mixin_uuid
  belongs_to :collectible, primary_key: :token_id, foreign_key: :token_id, inverse_of: :non_fungible_outputs

  before_validation :setup_attributes

  default_scope -> { order(Arel.sql("(raw->>'updated_at')::timestamptz desc")) }

  delegate :collection, :nft_collection, to: :collectible

  private

  def setup_attributes
    return if raw.blank?

    assign_attributes(
      state: raw['state'],
      token_id: raw['token_id']
    )
  end
end
