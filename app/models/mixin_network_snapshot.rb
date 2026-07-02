# frozen_string_literal: true

# == Schema Information
#
# Table name: mixin_network_snapshots
# Database name: primary
#
#  id             :bigint           not null, primary key
#  amount         :decimal(, )
#  data           :string
#  processed_at   :datetime
#  transferred_at :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  asset_id       :uuid
#  opponent_id    :uuid
#  snapshot_id    :uuid
#  trace_id       :uuid
#  user_id        :uuid
#
# Indexes
#
#  index_mixin_network_snapshots_on_created_at    (created_at)
#  index_mixin_network_snapshots_on_processed_at  (processed_at)
#  index_mixin_network_snapshots_on_snapshot_id   (snapshot_id) UNIQUE
#  index_mixin_network_snapshots_on_trace_id      (trace_id)
#  index_mixin_network_snapshots_on_user_id       (user_id)
#

class MixinNetworkSnapshot < ApplicationRecord
  POLLING_INTERVAL = 0.1
  POLLING_LIMIT = 500

  belongs_to :wallet, class_name: "MixinNetworkUser", foreign_key: :user_id, primary_key: :uuid, inverse_of: :snapshots, optional: true
  belongs_to :opponent, class_name: "User", primary_key: :mixin_uuid, optional: true
  belongs_to :opponent_wallet, class_name: "MixinNetworkUser", primary_key: :uuid, foreign_key: :opponent_id, inverse_of: false, optional: true
  belongs_to :currency, primary_key: :asset_id, foreign_key: :asset_id, inverse_of: :orders, optional: true

  validates :amount, presence: true
  validates :asset_id, presence: true
  validates :user_id, presence: true
  validates :snapshot_id, presence: true
  validates :trace_id, presence: true
  validates :transferred_at, presence: true

  after_commit :process_async, on: :create

  scope :processed, -> { where.not(processed_at: nil) }
  scope :unprocessed, -> { where(processed_at: nil) }
  scope :only_input, -> { where(amount: 0...) }
  scope :only_output, -> { where(amount: ...0) }
  scope :only_quill, -> { where(user_id: QuillBot.api.client_id) }

  def self.poll
    @__retry = 0

    loop do
      offset = last_polled_at

      r = QuillBot.api.safe_snapshots(offset:, limit: POLLING_LIMIT, order: "ASC", app: QuillBot.api.client_id)
      p "polled #{r['data'].length} mixin SAFE snapshots, since #{offset}"

      r["data"].each do |snapshot|
        next if snapshot["user_id"].blank?

        data =
          begin
            [ snapshot["memo"] ].pack("H*")
          rescue StandardError => e
            logger.error e.inspect
            nil
          end

        create_with(
          asset_id: snapshot["asset_id"],
          amount: snapshot["amount"],
          data:,
          transferred_at: snapshot["created_at"],
          user_id: snapshot["user_id"],
          opponent_id: snapshot["opponent_id"],
          snapshot_id: snapshot["snapshot_id"],
          trace_id: snapshot["request_id"]
        ).find_or_create_by!(
          snapshot_id: snapshot["snapshot_id"]
        )
      end

      Rails.cache.write "last_polled_at", r["data"].last["created_at"] if r["data"].length.positive?

      if r["data"].length < POLLING_LIMIT
        # pull down the kernel outputs
        sleep POLLING_INTERVAL * 10
      else
        sleep POLLING_INTERVAL
      end

      @__retry = 0
    rescue MixinBot::ResponseError, MixinBot::HttpError, MixinBot::RequestError, OpenSSL::SSL::SSLError => e
      logger.error e.inspect
      raise e if @__retry > 10

      sleep POLLING_INTERVAL * 10
      @__retry += 1

      retry
    rescue ActiveRecord::StatementInvalid => e
      logger.error e.inspect
      ActiveRecord::Base.connection.reconnect!

      retry
    rescue StandardError => e
      logger.error "#{e.inspect}\n#{e.backtrace.join("\n")}"
      ExceptionNotifier.notify_exception e if Rails.env.production?
      raise e if Rails.env.production?

      sleep POLLING_INTERVAL * 10
    end
  end

  def self.last_polled_at
    Rails.cache.fetch("last_polled_at") do
      MixinNetworkSnapshot.order(transferred_at: :desc).first&.transferred_at&.utc&.rfc3339 || Time.current.utc.rfc3339
    end
  end

  def owner
    @owner = wallet&.owner
  end

  def article
    @article = owner.is_a?(Article) && owner
  end

  def decoded_memo
    @decoded_memo =
      begin
        JSON.parse Base64.decode64(data.to_s)
      rescue JSON::ParserError
        {}
      end
  end

  def payment_memo_correct?
    decoded_memo.key?("t") &&
      decoded_memo["t"].in?(%w[BUY REWARD CITE REVENUE]) &&
      (decoded_memo.key?("a") || decoded_memo.key?("l"))
  end

  def processed?
    processed_at?
  end

  def process!
    return if processed?

    if legacy_4swap_snapshot?
      notify_legacy_4swap_snapshot
    elsif amount.positive?
      process_payment_snapshot
    end

    touch_proccessed_at
  end

  # The 4swap/Pando Lake cross-asset payment path has been retired, but a
  # snapshot using its memo protocol could still arrive if a trade was
  # in-flight at deploy time. Surface it loudly instead of silently marking
  # it processed with no follow-up action.
  def legacy_4swap_snapshot?
    decoded_memo["s"].in? %w[4swapTrade 4swapRefund]
  end

  def notify_legacy_4swap_snapshot
    error = StandardError.new("Received legacy 4swap snapshot after removal of the swap payment path")
    Rails.logger.error "#{error.message}: snapshot_id=#{snapshot_id}, trace_id=#{trace_id}"
    ExceptionNotifier.notify_exception(error, data: { snapshot_id:, trace_id:, memo: decoded_memo }) if Rails.env.production?
  end

  def process_payment_snapshot
    return if amount.negative?
    # not valid payment
    return unless payment_memo_correct?

    Currency.find_or_create_by(asset_id:)
    Payment
      .create_with(
        raw: {
          amount:,
          memo: data,
          asset_id:,
          opponent_id:,
          snapshot_id:,
          trace_id:
        }
      ).find_or_create_by!(trace_id:)
  end

  def touch_proccessed_at
    update processed_at: Time.current
  end

  def process_async
    MixinNetworkSnapshots::ProcessJob.perform_later id
  end

  def price_tag
    [ format("%.8f", amount), currency.symbol ].join(" ")
  end

  def snapshot_url
    format("https://mixin.one/%<snapshot_id>s", snapshot_id:)
  end
end
