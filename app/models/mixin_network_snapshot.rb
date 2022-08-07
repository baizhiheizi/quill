# frozen_string_literal: true

# == Schema Information
#
# Table name: mixin_network_snapshots
#
#  id             :bigint           not null, primary key
#  amount         :decimal(, )
#  data           :string
#  processed_at   :datetime
#  raw            :json
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

  before_validation :setup_attributes, on: :create

  validates :amount, presence: true
  validates :asset_id, presence: true
  validates :user_id, presence: true
  validates :snapshot_id, presence: true
  validates :trace_id, presence: true

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
    loop do
      offset = Global.redis.get('last_polled_at')
      offset = MixinNetworkSnapshot.order(transferred_at: :desc).first&.transferred_at&.utc&.rfc3339 || Time.current.utc.rfc3339 if offset.blank?

      r = QuillBot.api.read_network_snapshots(offset: offset, limit: POLLING_LIMIT, order: 'ASC')
      p "polled #{r['data'].length} mixin network snapshots, since #{offset}"

      r['data'].each do |snapshot|
        next if snapshot['user_id'].blank?

        create_with(raw: snapshot).find_or_create_by!(snapshot_id: snapshot['snapshot_id'])
      end

      Global.redis.set 'last_polled_at', r['data'].last['created_at']

      sleep 0.5 if r['data'].length < POLLING_LIMIT
      sleep POLLING_INTERVAL
    rescue MixinBot::HttpError, MixinBot::RequestError, OpenSSL::SSL::SSLError => e
      p e.inspect
      sleep POLLING_INTERVAL * 10
    rescue StandardError => e
      p "#{e.inspect}\n#{e.backtrace.join("\n")}"
      ExceptionNotifier.notify_exception e
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

  def payment_memo_correct?
    decoded_memo.key?('a') && decoded_memo.key?('t') && decoded_memo['t'].in?(%w[BUY REWARD CITE REVENUE])
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
    end

    touch_proccessed_at
  end

  def process_payment_snapshot
    return if amount.negative?
    # not valid payment
    return unless payment_memo_correct?

    Currency.find_or_create_by asset_id: asset_id
    Payment
      .create_with(raw: raw)
      .find_or_create_by!(trace_id: trace_id)
  end

  def process_4swap_snapshot
    return if amount.negative?

    swap_order = SwapOrder.find_by trace_id: decoded_memo['t']

    case decoded_memo['s']
    when '4swapTrade'
      swap_order.update! amount: amount
      if swap_order.swapping?
        swap_order.swap!
      elsif swap_order.swapped?
        swap_order.place_payment_order!
      end
    when '4swapRefund'
      swap_order.reject! if swap_order.may_reject?
    end
    # TODO: raise if still swapping/swapped
  end

  def touch_proccessed_at
    update processed_at: Time.current
  end

  def process_async
    if amount.negative?
      touch_proccessed_at
    else
      ProcessMixinNetworkSnapshotWorker.perform_async id
    end
  end

  def price_tag
    [format('%.8f', amount), currency.symbol].join(' ')
  end

  def snapshot_url
    format('https://mixin.one/%<snapshot_id>s', snapshot_id: snapshot_id)
  end

  private

  def setup_attributes
    return unless new_record?

    assign_attributes(
      asset_id: raw['asset']['asset_id'],
      amount: raw['amount'],
      data: raw['data'],
      transferred_at: raw['created_at'],
      user_id: raw['user_id'],
      opponent_id: raw['opponent_id'],
      snapshot_id: raw['snapshot_id'],
      trace_id: raw['trace_id']
    )
  end
end
