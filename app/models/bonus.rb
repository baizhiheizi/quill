# frozen_string_literal: true

# == Schema Information
#
# Table name: bonuses
#
#  id          :bigint           not null, primary key
#  amount      :decimal(, )
#  description :text
#  state       :string
#  title       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  asset_id    :string
#  trace_id    :uuid
#  user_id     :bigint
#
# Indexes
#
#  index_bonuses_on_trace_id  (trace_id) UNIQUE
#  index_bonuses_on_user_id   (user_id)
#
class Bonus < ApplicationRecord
  include AASM

  belongs_to :user

  has_one :transfer, as: :source, dependent: :nullify

  before_validation :setup_attributes

  validates :title, presence: true
  validates :asset_id, presence: true
  validates :trace_id, presence: true
  validates :amount, numericality: { greater_than: 0.000_000_01 }

  aasm column: :state do
    state :drafted, initial: true
    state :delivering
    state :completed

    event :deliver, guard: :ensure_transfer_created do
      transitions from: :drafted, to: :delivering
    end

    event :complete do
      transitions from: :delivering, to: :completed
    end
  end

  def ensure_transfer_created
    transfer.presence ||
      create_transfer!(
        transfer_type: :bonus,
        opponent_id: user.mixin_uuid,
        amount: amount,
        asset_id: asset_id,
        trace_id: trace_id,
        memo: "[Bonus]#{title}"
      )
  end

  private

  def setup_attributes
    assign_attributes(
      asset_id: Article::PRS_ASSET_ID,
      trace_id: SecureRandom.uuid
    )
  end
end
