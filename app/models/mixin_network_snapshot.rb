# frozen_string_literal: true

# == Schema Information
#
# Table name: mixin_network_snapshots
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

  belongs_to :wallet, class_name: 'MixinNetworkUser', foreign_key: :user_id, primary_key: :uuid, inverse_of: :snapshots, optional: true
  belongs_to :opponent, class_name: 'User', primary_key: :mixin_uuid, optional: true
  belongs_to :opponent_wallet, class_name: 'MixinNetworkUser', primary_key: :uuid, foreign_key: :opponent_id, inverse_of: false, optional: true
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
  scope :only_4swap, -> { where(opponent_id: [SwapOrder::FOX_SWAP_APP_ID, nil]) }

  # polling Mixin Network
  # should be called in a event machine
  def self.poll
    @__retry = 0

    loop do
      offset = last_polled_at

      r = QuillBot.api.network_snapshots(offset:, limit: POLLING_LIMIT, order: 'ASC')
      p "polled #{r['data'].length} mixin network snapshots, since #{offset}"

      r['data'].each do |snapshot|
        next if snapshot['user_id'].blank?

        create_with(
          asset_id: snapshot['asset']['asset_id'],
          amount: snapshot['amount'],
          data: snapshot['data'],
          transferred_at: snapshot['created_at'],
          user_id: snapshot['user_id'],
          opponent_id: snapshot['opponent_id'],
          snapshot_id: snapshot['snapshot_id'],
          trace_id: snapshot['trace_id']
        ).find_or_create_by!(
          snapshot_id: snapshot['snapshot_id']
        )
      end

      Rails.cache.write 'last_polled_at', r['data'].last['created_at']

      sleep 0.5 if r['data'].length < POLLING_LIMIT
      sleep POLLING_INTERVAL
      @__retry = 0
    rescue MixinBot::HttpError, MixinBot::RequestError, OpenSSL::SSL::SSLError => e
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
      ExceptionNotifier.notify_exception e
      raise e if Rails.env.production?

      sleep POLLING_INTERVAL * 10
    end
  end

  def self.last_polled_at
    Rails.cache.fetch('last_polled_at') do
      MixinNetworkSnapshot.order(transferred_at: :desc).first&.transferred_at&.utc&.rfc3339 || Time.current.utc.rfc3339
    end
  end

  # polling Mixin Safe Network
  def self.safe_poll
    @__retry = 0

    loop do
      offset = last_polled_at

      r = QuillBot.api.safe_snapshots(offset:, limit: POLLING_LIMIT, order: 'ASC', app: QuillBot.api.client_id)
      p "polled #{r['data'].length} mixin SAFE snapshots, since #{offset}"

      r['data'].each do |snapshot|
        next if snapshot['user_id'].blank?

        data =
          begin
            [snapshot['memo']].pack('H*')
          rescue StandardError => e
            logger.error e.inspect
            nil
          end

        create_with(
          asset_id: snapshot['asset_id'],
          amount: snapshot['amount'],
          data:,
          transferred_at: snapshot['created_at'],
          user_id: snapshot['user_id'],
          opponent_id: snapshot['opponent_id'],
          snapshot_id: snapshot['snapshot_id'],
          trace_id: snapshot['request_id']
        ).find_or_create_by!(
          snapshot_id: snapshot['snapshot_id']
        )
      end

      Rails.cache.write 'last_polled_at', r['data'].last['created_at'] if r['data'].length.positive?

      if r['data'].length < POLLING_LIMIT
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

  def owner
    @owner = wallet&.owner
  end

  def article
    @article = owner.is_a?(Article) && owner
  end

  def decoded_memo
    # memo from 4swap
    # memo = {
    #   s: '4swapTrade|4swapRefund',
    #   t: 'trace_id'
    # }
    @decoded_memo =
      begin
        JSON.parse Base64.decode64(data.to_s)
      rescue JSON::ParserError
        {}
      end
  end

  def collectible
    return unless (amount.to_f + Collectible::MINT_FEE).zero?
    return unless asset_id == Collectible::MINT_ASSET_ID

    nfo = MixinBot::Utils::Nfo.new(memo: data.to_s).decode
    @collectible ||= Collectible.find_by metahash: nfo.extra
  rescue ArgumentError
    nil
  end

  def payment_memo_correct?
    decoded_memo.key?('t') &&
      decoded_memo['t'].in?(%w[BUY REWARD CITE REVENUE MINT]) &&
      (decoded_memo.key?('a') || decoded_memo.key?('l'))
  end

  def processed?
    processed_at?
  end

  def process!
    return if processed?

    if decoded_memo['s'].in? %w[4swapTrade 4swapRefund]
      process_4swap_snapshot
    elsif amount.positive?
      process_payment_snapshot
    elsif collectible.present?
      collectible.transfer_to_owner_async
    end

    touch_proccessed_at
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

  def process_4swap_snapshot
    return if amount.negative?

    swap_order = SwapOrder.find_by trace_id: decoded_memo['t']
    pre_order = PreOrder.find_by follow_id: decoded_memo['t']

    if swap_order.present?
      case decoded_memo['s']
      when '4swapTrade'
        swap_order.update!(amount:)
        if swap_order.swapping?
          swap_order.swap!
        elsif swap_order.swapped?
          swap_order.place_payment_order!
        end
      when '4swapRefund'
        swap_order.reject! if swap_order.may_reject?
      end
    elsif pre_order.present?
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
  end

  def touch_proccessed_at
    update processed_at: Time.current
  end

  def process_async
    MixinNetworkSnapshots::ProcessJob.perform_later id
  end

  def price_tag
    [format('%.8f', amount), currency.symbol].join(' ')
  end

  def snapshot_url
    format('https://mixin.one/%<snapshot_id>s', snapshot_id:)
  end
end
