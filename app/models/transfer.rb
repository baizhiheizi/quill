# frozen_string_literal: true

# == Schema Information
#
# Table name: transfers
# Database name: primary
#
#  id                :bigint           not null, primary key
#  amount            :decimal(, )
#  memo              :string
#  opponent_multisig :json
#  processed_at      :datetime
#  queue_priority    :integer          default("default")
#  retry_at          :datetime
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
  PENDING_BATCH_LIMIT = 20

  belongs_to :source, polymorphic: true, optional: true
  belongs_to :wallet, class_name: "MixinNetworkUser", primary_key: :uuid, inverse_of: :transfers, optional: true
  belongs_to :recipient, class_name: "User", primary_key: :mixin_uuid, foreign_key: :opponent_id, inverse_of: :transfers, optional: true
  belongs_to :currency, primary_key: :asset_id, foreign_key: :asset_id, inverse_of: :transfers, optional: true

  enum :queue_priority, { default: 0, critical: 1, high: 2, low: 3 }, prefix: true
  enum :transfer_type, {
    default: -1,
    author_revenue: 0,
    reader_revenue: 1,
    payment_refund: 2,
    quill_revenue: 3,
    bonus: 4,
    swap_change: 5,
    swap_refund: 6,
    fox_swap: 7,
    withdraw_balance: 8,
    reference_revenue: 9,
    mint_nft: 10 # historical records only
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
    _snapshot = snapshot.is_a?(Array) ? snapshot.first : snapshot
    _snapshot&.[]("snapshot_id")
  end

  def transaction_hash
    _snapshot = snapshot.is_a?(Array) ? snapshot.first : snapshot
    _snapshot&.[]("transaction_hash")
  end

  def snapshot_url
    if transaction_hash.present?
      [
        "https://viewblock.io/mixin/tx/",
        transaction_hash
      ].join
    elsif snapshot_id.present?
      [
        "https://mixin.one/snapshots/",
        snapshot_id
      ].join
    end
  end

  def processed?
    processed_at?
  end

  def process!
    return if processed?

    process_safe_transfer!

    # source_type is filtered first so a stale source_type referencing a
    # class that is no longer autoloaded never reaches the polymorphic
    # `source` lookup (which would raise NameError).
    case source_type
    when "Payment"
      source.refund! if source.may_refund?
    when "Bonus"
      source.complete! if source.may_complete?
    end

    notify_recipient if recipient.present?
  end

  def process_with_rescue!
    with_lock("FOR UPDATE NOWAIT") do
      reload
      return if processed?

      Rails.logger.info "Transfer processing ##{id} #{Time.current}"
      process!
    end
  rescue ActiveRecord::LockWaitTimeout, ActiveRecord::StatementInvalid => e
    raise unless lock_not_available?(e)

    Rails.logger.info "Transfer ##{id} already locked, skipping"
  rescue MixinBot::UserNotFoundError
    Rails.logger.warn "Transfer user not found ##{id} #{Time.current}"

    if retry_at.blank? || created_at > 7.days.ago
      recipient&.notify_for_safe_registration
      update retry_at: 1.day.from_now
    else
      update retry_at: 7.days.from_now
    end
  rescue MixinBot::InsufficientBalanceError
    Rails.logger.warn "Transfer insufficient balance ##{id} #{Time.current}"
  rescue MixinBot::RateLimitError => e
    defer_for_mixin_api!(e)
  rescue StandardError => e
    if MixinBot.retryable?(e)
      defer_for_mixin_api!(e)
    else
      Rails.logger.error e
    end
  end

  def safe_receiver
    @safe_receiver ||=
      if opponent_id.present?
        {
          members: [ opponent_id ],
          threshold: 1,
          amount:
        }
      else
        {
          members: opponent_multisig["receivers"],
          threshold: opponent_multisig["threshold"],
          amount:
        }
      end
  end

  def process_safe_transfer!
    check!
    return if processed?

    r = QuillBot.api.create_safe_transfer(
      members: safe_receiver[:members],
      threshold: safe_receiver[:threshold],
      amount: safe_receiver[:amount],
      asset_id:,
      request_id: trace_id,
      memo:
    )

    update!(
      snapshot: r["data"],
      processed_at: Time.current
    )
  end

  def check!
    r = QuillBot.api.safe_transaction trace_id

    update!(
      snapshot: r["data"],
      processed_at: Time.current
    )
  rescue MixinBot::NotFoundError
    false
  end

  def notify_recipient
    return if recipient.blank?
    return if currency.blank?

    TransferProcessedNotifier.with(record: self, transfer: self).deliver(recipient)
  end

  def price_tag
    [ format("%.8f", amount), currency.symbol ].join(" ")
  end

  def process_async
    Transfers::ProcessJob.perform_later trace_id
  end

  def recipient_has_safe?
    recipient&.has_safe?
  end

  def self.author_revenue_total_in_usd
    Rails.cache.fetch("author_revenue_total_in_usd", expires_in: 1.minute) do
      joins(:currency).where(transfer_type: :author_revenue).sum("amount * currencies.price_usd").to_f.round(4)
    end
  end

  def self.reader_revenue_total_in_usd
    Rails.cache.fetch("reader_revenue_total_in_usd", expires_in: 1.minute) do
      joins(:currency).where(transfer_type: :reader_revenue).sum("amount * currencies.price_usd").to_f.round(4)
    end
  end

  def self.stats
    Rails.cache.fetch("transfer_stats", expires_in: 15.minutes) do
      cal_stats
    end
  end

  def self.write_stats
    Rails.cache.write "transfer_stats", cal_stats
  end

  def self.cal_stats
    {
      author_revenue_total_in_usd: Transfer.author_revenue_total_in_usd,
      reader_revenue_total_in_usd: Transfer.reader_revenue_total_in_usd,
      platform_revenue_last_month: (Order.where(created_at: Time.current.last_month.beginning_of_month...Time.current.last_month.end_of_month).sum(:value_usd) * Order::PLATFORM_RATIO).round(4),
      platform_revenue_this_month: (Order.where(created_at: Time.current.beginning_of_month...).sum(:value_usd) * Order::PLATFORM_RATIO).round(4)
    }.stringify_keys
  end

  def self.process_pending!
    if MixinApi::Gate.throttled?(:quill_bot)
      Rails.logger.info(
        format(
          "[Transfer] skipping process_pending! — quill_bot backoff remaining %.1fs",
          MixinApi::Gate.backoff_remaining(:quill_bot)
        )
      )
      return
    end

    unprocessed
      .where("retry_at IS NULL OR retry_at < ?", Time.current)
      .order(:created_at)
      .limit(PENDING_BATCH_LIMIT)
      .each(&:process_with_rescue!)
  end

  private

  def defer_for_mixin_api!(error)
    remaining = MixinApi::Gate.backoff_remaining(:quill_bot)
    delay = remaining.positive? ? remaining : 30.seconds
    Rails.logger.warn "Transfer ##{id} deferred for Mixin API (#{error.class}): retry in #{delay.round(1)}s"
    update!(retry_at: Time.current + delay)
  end

  def lock_not_available?(error)
    return true if error.is_a?(ActiveRecord::LockWaitTimeout)

    cause = error.cause
    cause.is_a?(PG::LockNotAvailable) || error.message.include?("could not obtain lock")
  end

  def ensure_opponent_presence
    errors.add(:opponent_id, " must cannot be blank") if opponent_id.blank? && opponent_multisig.blank?
  end
end
