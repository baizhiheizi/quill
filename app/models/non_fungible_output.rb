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
#  output_id  :uuid
#  token_id   :uuid
#  user_id    :uuid
#
# Indexes
#
#  index_non_fungible_outputs_on_output_id  (output_id) UNIQUE
#  index_non_fungible_outputs_on_token_id   (token_id)
#  index_non_fungible_outputs_on_user_id    (user_id)
#
class NonFungibleOutput < ApplicationRecord
  belongs_to :user, primary_key: :mixin_uuid
  belongs_to :collectible, primary_key: :token_id, foreign_key: :token_id, inverse_of: :non_fungible_outputs, optional: true

  before_validation :setup_attributes

  default_scope -> { order(Arel.sql("(raw->>'updated_at')::timestamptz desc")) }

  delegate :collection, :nft_collection, to: :collectible

  after_commit :notify, on: :create

  def notify
    return unless state == 'unspent'
    return if collectible&.collection.blank?

    NonFungibleOutputFoundNotification.with(non_fungible_output: self).deliver(user)
  end

  private

  def setup_attributes
    return if raw.blank?

    assign_attributes(
      state: raw['state'],
      token_id: raw['token_id'],
      output_id: raw['output_id']
    )
  end
end
