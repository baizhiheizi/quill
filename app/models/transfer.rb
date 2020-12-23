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
#  wallet_id     :uuid
#
# Indexes
#
#  index_transfers_on_source_type_and_source_id  (source_type,source_id)
#  index_transfers_on_trace_id                   (trace_id) UNIQUE
#  index_transfers_on_wallet_id                  (wallet_id)
#
class Transfer < ApplicationRecord
  belongs_to :source, polymorphic: true
  belongs_to :wallet, class_name: 'MixinNetworkUser', primary_key: :uuid, inverse_of: :transfers, optional: true
  belongs_to :recipient, class_name: 'User', primary_key: :mixin_uuid, foreign_key: :opponent_id, inverse_of: :transfers, optional: true

  has_one :article, class_name: 'Article', through: :source, source: :item

  enum transfer_type: { author_revenue: 0, reader_revenue: 1, payment_refund: 2, prsdigg_revenue: 3, bonus: 4 }

  validates :trace_id, presence: true, uniqueness: true
  validates :asset_id, presence: true
  validates :opponent_id, presence: true

  after_commit :process_async, on: :create

  scope :unprocessed, -> { where(processed_at: nil) }
  scope :processed, -> { where.not(processed_at: nil) }
  scope :only_user_revenue, -> { where(transfer_type: %i[author_revenue reader_revenue]) }

  def snapshot_id
    snapshot&.[]('snapshot_id')
  end

  def processed?
    processed_at?
  end

  def process!
    return if processed?

    r =
      if wallet.blank?
        PrsdiggBot.api.create_transfer(
          Rails.application.credentials.dig(:mixin, :pin_code),
          asset_id: asset_id,
          opponent_id: opponent_id,
          amount: amount,
          trace_id: trace_id,
          memo: memo
        )
      else
        wallet.mixin_api.create_transfer(
          wallet.pin,
          asset_id: asset_id,
          opponent_id: opponent_id,
          amount: amount,
          trace_id: trace_id,
          memo: memo
        )
      end

    raise r['error'].inspect if r['error'].present?
    return unless r['data']['trace_id'] == trace_id

    with_lock do
      source.refund! if payment_refund?
      source.complete! if bonus?
      update!(
        snapshot: r['data'],
        processed_at: Time.current
      )
    end

    notify_recipient if wallet.present?
  end

  def notify_recipient
    TransferNotificationService.new.call(
      recipient_id: opponent_id,
      asset_id: asset_id,
      amount: amount,
      trace_id: trace_id
    )
  end

  def process_async
    ProcessTransferWorker.perform_async trace_id
  end
end
