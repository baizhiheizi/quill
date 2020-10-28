# frozen_string_literal: true

# == Schema Information
#
# Table name: transfers
#
#  id            :bigint           not null, primary key
#  amount        :decimal(, )
#  memo          :string
#  processed_at  :datetime
#  snapshot      :json
#  source_type   :string
#  transfer_type :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  asset_id      :uuid
#  opponent_id   :uuid
#  source_id     :bigint
#  trace_id      :uuid
#
# Indexes
#
#  index_transfers_on_source_type_and_source_id  (source_type,source_id)
#  index_transfers_on_trace_id                   (trace_id) UNIQUE
#
class Transfer < ApplicationRecord
  belongs_to :source, polymorphic: true
  belongs_to :receiver, class_name: 'User', primary_key: :mixin_uuid, foreign_key: :opponent_id, inverse_of: :transfers

  enum transfer_type: { author_revenue: 0, reader_revenue: 1, payment_refund: 2 }

  validates :trace_id, presence: true, uniqueness: true
  validates :asset_id, presence: true
  validates :opponent_id, presence: true

  after_create :process_async

  scope :unprocessed, -> { where(processed_at: nil) }
  scope :processed, -> { where.not(processed_at: nil) }

  def snapshot_id
    snapshot&.[]('snapshot_id')
  end

  def processed?
    processed_at?
  end

  def process!
    return if processed?

    r = MixinBot.api.create_transfer(
      Rails.application.credentials.dig(:mixin, :pin_code),
      asset_id: asset_id,
      opponent_id: opponent_id,
      amount: amount,
      trace_id: trace_id,
      memo: memo
    )

    raise r['error'].inspect if r['error'].present?
    return unless r['data']['trace_id'] == trace_id

    with_lock do
      source.refund! if payment_refund?
      update!(
        snapshot: r['data'],
        processed_at: Time.current
      )
    end
  end

  def process_async
    ProcessTransferWorker.perform_async trace_id
  end
end
