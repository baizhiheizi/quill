# frozen_string_literal: true

# == Schema Information
#
# Table name: payments
#
#  id          :bigint           not null, primary key
#  amount      :decimal(, )
#  memo        :string
#  raw         :json
#  state       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  asset_id    :uuid
#  opponent_id :uuid
#  snapshot_id :uuid
#  trace_id    :uuid
#
# Indexes
#
#  index_payments_on_trace_id  (trace_id) UNIQUE
#
class Payment < ApplicationRecord
  belongs_to :payer, class_name: 'User', foreign_key: :mixin_uuid, primary_key: :opponent_id, inverse_of: :payments

  before_validation :setup_attributes

  validates :amount, presence: true
  validates :raw, presence: true
  validates :asset_id, presence: true
  validates :opponent_id, presence: true
  validates :snapshot_id, presence: true, uniqueness: true
  validates :trace_id, presence: true, uniqueness: true

  after_commit :create_order!, on: :create

  def create_order!
    decpreted_memo =
      begin
        JSON.parse Base64.decode64(snapshot['memo'])
      rescue JSON::ParserError
        {}
      end

    case decpreted_memo['type']
    when 'BUY'
      # TODO: create buy article order
    when 'REWARD'
      # TODO: create reward article order
    else
      refund
    end
  rescue StandardError
    retund
  end

  def refund
    # TODO: create refund transfer worker
  end

  private

  def setup_attributes
    assign_attributes(
      amount: raw['amount'].to_f,
      memo: raw['memo'],
      asset_id: raw['asset_id'],
      opponent_id: raw['opponent_id'],
      snapshot_id: raw['snapshot_id'],
      trace_id: raw['trace_id']
    )
  end
end
