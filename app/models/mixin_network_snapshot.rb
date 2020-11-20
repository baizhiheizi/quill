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
#  index_mixin_network_snapshots_on_trace_id  (trace_id) UNIQUE
#  index_mixin_network_snapshots_on_user_id   (user_id)
#
class MixinNetworkSnapshot < ApplicationRecord
  POLLING_INTERVAL = 0.1
  POLLING_LIMIT = 500

  belongs_to :wallet, class_name: 'MixinNetworkUser', foreign_key: :user_id, primary_key: :uuid, inverse_of: :snapshots, optional: true
  belongs_to :opponent, class_name: 'User', primary_key: :mixin_uuid, inverse_of: :snapshots, optional: true

  before_validation :setup_attributes, on: :create

  validates :amount, presence: true
  validates :asset_id, presence: true
  validates :user_id, presence: true
  validates :snapshot_id, presence: true
  validates :trace_id, presence: true

  after_commit :process_async, on: :create

  scope :unprocessed, -> { where(processed_at: nil) }
  scope :only_input, -> { where(amount: 0...) }
  scope :only_output, -> { where(amount: ...0) }
  scope :only_prsdigg, -> { where(user_id: MixinBot.client_id) }

  # polling Mixin Network
  # should be called in a event machine
  def self.poll
    loop do
      offset = Global.redis.get('last_polled_at')
      offset = MixinNetworkSnapshot.order(transferred_at: :desc).first&.transferred_at&.utc&.rfc3339 || Time.current.utc.rfc3339 if offset.blank?

      r = MixinBot.api.read_network_snapshots(offset: offset, limit: POLLING_LIMIT, order: 'ASC')
      p ['polled', r['data'].length]

      r['data'].each do |snapshot|
        next if snapshot['user_id'].blank?

        create_with(raw: snapshot).find_or_create_by!(trace_id: snapshot['trace_id'])
      end

      Global.redis.set 'last_polled_at', r['data'].last['created_at']

      sleep 0.5 if r['data'].length < POLLING_LIMIT
      sleep POLLING_INTERVAL
    rescue StandardError => e
      p e.inspect
      Rails.logger.error e.inspect
    end
  end

  def owner
    wallet&.owner
  end

  def article
    owner.is_a?(Article) && owner
  end

  def processed?
    processed_at?
  end

  def process!
    return if processed?

    process_article_snapshot if wallet&.owner_type == 'Article'

    touch_proccessed_at
  end

  def process_article_snapshot
    return if amount.negative?

    Payment
      .create_with(raw: raw)
      .find_or_create_by!(trace_id: trace_id)
  end

  def touch_proccessed_at
    update processed_at: Time.current
  end

  def process_async
    ProcessMixinNetworkSnapshotWorker.perform_async id
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
