# frozen_string_literal: true

# == Schema Information
#
# Table name: transfers
#
#  id             :bigint           not null, primary key
#  amount         :decimal(, )
#  memo           :string
#  processed_at   :datetime
#  queue_priority :integer          default("default")
#  snapshot       :json
#  source_type    :string
#  transfer_type  :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  asset_id       :uuid
#  opponent_id    :uuid
#  source_id      :bigint
#  trace_id       :uuid
#  wallet_id      :uuid
#
# Indexes
#
#  index_transfers_on_asset_id                   (asset_id)
#  index_transfers_on_source_type_and_source_id  (source_type,source_id)
#  index_transfers_on_trace_id                   (trace_id) UNIQUE
#  index_transfers_on_wallet_id                  (wallet_id)
#
class Transfer < ApplicationRecord
  MINIMUM_AMOUNT = 0.000_000_01

  belongs_to :source, polymorphic: true
  belongs_to :wallet, class_name: 'MixinNetworkUser', primary_key: :uuid, inverse_of: :transfers, optional: true
  belongs_to :recipient, class_name: 'User', primary_key: :mixin_uuid, foreign_key: :opponent_id, inverse_of: :transfers, optional: true
  belongs_to :currency, primary_key: :asset_id, foreign_key: :asset_id, inverse_of: :transfers, optional: true

  has_one :article, class_name: 'Article', through: :source, source: :item

  enum queue_priority: { default: 0, critical: 1, high: 2, low: 3 }, _prefix: true
  enum transfer_type: {
    author_revenue: 0,
    reader_revenue: 1,
    payment_refund: 2,
    prsdigg_revenue: 3,
    bonus: 4,
    swap_change: 5,
    swap_refund: 6,
    fox_swap: 7
  }

  validates :trace_id, presence: true, uniqueness: true
  validates :asset_id, presence: true
  validates :opponent_id, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: MINIMUM_AMOUNT }

  after_create :update_recipient_statistics_cache
  after_commit :process_async, on: :create

  scope :unprocessed, -> { where(processed_at: nil) }
  scope :processed, -> { where.not(processed_at: nil) }
  scope :only_user_revenue, -> { where(transfer_type: %i[author_revenue reader_revenue]) }
  scope :only_prs, -> { where(asset_id: Currency::PRS_ASSET_ID) }
  scope :only_btc, -> { where(asset_id: Currency::BTC_ASSET_ID) }

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
          Rails.application.credentials.dig(:prsdigg_bot, :pin_code),
          {
            asset_id: asset_id,
            opponent_id: opponent_id,
            amount: amount,
            trace_id: trace_id,
            memo: memo
          }
        )
      else
        wallet.mixin_api.create_transfer(
          wallet.pin,
          {
            asset_id: asset_id,
            opponent_id: opponent_id,
            amount: amount,
            trace_id: trace_id,
            memo: memo
          }
        )
      end

    raise r['error'].inspect if r['error'].present?
    return unless r['data']['trace_id'] == trace_id

    case transfer_type.to_sym
    when :payment_refund, :swap_refund
      source.refund! unless source.refunded?
    when :bonus, :swap_change
      source.complete! unless source.completed?
    when :fox_swap
      source.start! unless source.swapping?
    end
    update!(
      snapshot: r['data'],
      processed_at: Time.current
    )

    notify_recipient if recipient.present?
  end

  def notify_recipient
    return if recipient.blank?
    return if currency.blank?

    TransferProcessedNotification.with(transfer: self).deliver(recipient)
  end

  def price_tag
    [format('%.8f', amount), currency.symbol].join(' ')
  end

  def process_async
    if queue_priority_critical?
      ProcessCriticalTransferWorker.perform_async trace_id
    else
      ProcessTransferWorker.perform_async trace_id
    end
  end

  def update_recipient_statistics_cache
    return if recipient.blank?

    case asset_id
    when Currency::PRS_ASSET_ID
      recipient.update(
        author_revenue_total_prs: recipient.author_revenue_transfers.only_prs.sum(:amount).to_f,
        reader_revenue_total_prs: recipient.reader_revenue_transfers.only_prs.sum(:amount).to_f,
        revenue_total_prs: recipient.revenue_transfers.only_prs.sum(:amount).to_f
      )
    when Currency::BTC_ASSET_ID
      recipient.update(
        author_revenue_total_btc: recipient.author_revenue_transfers.only_btc.sum(:amount).to_f,
        reader_revenue_total_btc: recipient.reader_revenue_transfers.only_btc.sum(:amount).to_f,
        revenue_total_btc: recipient.revenue_transfers.only_btc.sum(:amount).to_f
      )
    end
  end

  def self.author_revenue_total_in_usd
    prs_amount = author_revenue.only_prs.sum(:amount)
    btc_amount = author_revenue.only_btc.sum(:amount)
    prs_amount * Currency.prs.price_usd.to_f + btc_amount * Currency.btc.price_usd.to_f
  end

  def self.reader_revenue_total_in_usd
    prs_amount = reader_revenue.only_prs.sum(:amount)
    btc_amount = reader_revenue.only_btc.sum(:amount)
    prs_amount * Currency.prs.price_usd.to_f + btc_amount * Currency.btc.price_usd.to_f
  end
end
