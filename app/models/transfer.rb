# frozen_string_literal: true

# == Schema Information
#
# Table name: transfers
#
#  id                :bigint           not null, primary key
#  amount            :decimal(, )
#  memo              :string
#  opponent_multisig :json
#  processed_at      :datetime
#  queue_priority    :integer          default("default")
#  snapshot          :json
#  source_type       :string
#  transfer_type     :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  asset_id          :uuid
#  opponent_id       :uuid
#  source_id         :bigint
#  trace_id          :uuid
#  wallet_id         :uuid
#
# Indexes
#
#  index_transfers_on_asset_id                   (asset_id)
#  index_transfers_on_created_at                 (created_at)
#  index_transfers_on_opponent_id                (opponent_id)
#  index_transfers_on_processed_at               (processed_at)
#  index_transfers_on_source_type_and_source_id  (source_type,source_id)
#  index_transfers_on_trace_id                   (trace_id) UNIQUE
#  index_transfers_on_transfer_type              (transfer_type)
#  index_transfers_on_wallet_id                  (wallet_id)
#

class Transfer < ApplicationRecord
  MINIMUM_AMOUNT = 0.000_000_01

  belongs_to :source, polymorphic: true, optional: true
  belongs_to :wallet, class_name: 'MixinNetworkUser', primary_key: :uuid, inverse_of: :transfers, optional: true
  belongs_to :recipient, class_name: 'User', primary_key: :mixin_uuid, foreign_key: :opponent_id, inverse_of: :transfers, optional: true
  belongs_to :currency, primary_key: :asset_id, foreign_key: :asset_id, inverse_of: :transfers, optional: true

  enum queue_priority: { default: 0, critical: 1, high: 2, low: 3 }, _prefix: true
  enum transfer_type: {
    author_revenue: 0,
    reader_revenue: 1,
    payment_refund: 2,
    quill_revenue: 3,
    bonus: 4,
    swap_change: 5,
    swap_refund: 6,
    fox_swap: 7,
    withdraw_balance: 8,
    reference_revenue: 9
  }

  validates :trace_id, presence: true, uniqueness: true
  validates :asset_id, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: MINIMUM_AMOUNT }
  validate :ensure_opponent_presence

  after_commit :process_async, on: :create

  scope :unprocessed, -> { where(processed_at: nil) }
  scope :processed, -> { where.not(processed_at: nil) }
  scope :only_user_revenue, -> { where(transfer_type: %i[author_revenue reader_revenue]) }

  def snapshot_id
    snapshot&.[]('snapshot_id')
  end

  def snapshot_url
    [
      'https://mixin.one/snapshots/',
      snapshot_id
    ].join
  end

  def processed?
    processed_at?
  end

  def process!
    return if processed?

    r =
      if wallet.blank?
        QuillBot.api.create_transfer(
          Rails.application.credentials.dig(:quill_bot, :pin_code),
          {
            asset_id: asset_id,
            opponent_id: opponent_id,
            amount: amount,
            trace_id: trace_id,
            memo: memo
          }
        )
      elsif opponent_id.present?
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
      else
        wallet.mixin_api.create_multisig_transaction(
          wallet.pin,
          {
            asset_id: asset_id,
            receivers: opponent_multisig['receivers'],
            threshold: opponent_multisig['threshold'],
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
    elsif queue_priority_low?
      ProcessThrottleTransferWorker.perform_in SecureRandom.random_number(600).seconds, trace_id, wallet_id
    else
      ProcessTransferWorker.perform_async trace_id
    end
  end

  def self.author_revenue_total_in_usd
    Rails.cache.fetch('author_revenue_total_in_usd', expires_in: 1.minute) do
      joins(:currency).where(transfer_type: :author_revenue).sum('amount * currencies.price_usd').to_f.round(4)
    end
  end

  def self.reader_revenue_total_in_usd
    Rails.cache.fetch('reader_revenue_total_in_usd', expires_in: 1.minute) do
      joins(:currency).where(transfer_type: :reader_revenue).sum('amount * currencies.price_usd').to_f.round(4)
    end
  end

  def self.stats
    Rails.cache.fetch('transfer_stats', expires_in: 10.minutes) do
      cal_stats
    end
  end

  def self.write_stats
    Rails.cache.write 'transfer_stats', cal_stats
  end

  def self.cal_stats
    {
      author_revenue_total_in_usd: Transfer.author_revenue_total_in_usd,
      reader_revenue_total_in_usd: Transfer.reader_revenue_total_in_usd,
      platform_revenue_last_month: (Order.where(created_at: Time.current.last_month.beginning_of_month...Time.current.last_month.end_of_month).sum(:value_usd) * Order::PLATFORM_RATIO).round(4),
      platform_revenue_this_month: (Order.where(created_at: Time.current.beginning_of_month...).sum(:value_usd) * Order::PLATFORM_RATIO).round(4)
    }.stringify_keys
  end

  private

  def ensure_opponent_presence
    errors.add(:opponent_id, ' must cannot be blank') if opponent_id.blank? && opponent_multisig.blank?
  end
end
