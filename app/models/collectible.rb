# frozen_string_literal: true

# == Schema Information
#
# Table name: collectibles
#
#  id            :bigint           not null, primary key
#  description   :string
#  identifier    :string
#  metadata      :jsonb
#  metahash      :string
#  name          :string
#  state         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  collection_id :uuid
#  token_id      :uuid
#
# Indexes
#
#  index_collectibles_on_collection_id_and_identifier  (collection_id,identifier) UNIQUE
#  index_collectibles_on_metahash                      (metahash) UNIQUE
#  index_collectibles_on_token_id                      (token_id) UNIQUE
#
class Collectible < ApplicationRecord
  include AASM

  belongs_to :collection

  validates :name, presence: true
  validates :description, presence: true
  validates :metahash, presence: true

  aasm column: :state do
    state :pending, initial: true
    state :minted

    event :mint do
      transitions from: :pending, to: :completed
    end
  end
end
