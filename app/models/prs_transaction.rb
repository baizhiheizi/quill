# frozen_string_literal: true

# == Schema Information
#
# Table name: prs_transactions
#
#  id              :bigint           not null, primary key
#  block_num       :integer
#  block_type      :string
#  hash_str        :string
#  raw             :jsonb
#  signature       :string
#  type(STI)       :string
#  user_address    :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  transation_id   :string
#  tx_id           :string
#
# Indexes
#
#  index_prs_transactions_on_block_num      (block_num) UNIQUE
#  index_prs_transactions_on_transation_id  (transation_id) UNIQUE
#  index_prs_transactions_on_tx_id          (tx_id) UNIQUE
#
class PrsTransaction < ApplicationRecord
  POLLING_INTERVAL = 0.1
  POLLING_START_TIME = Time.new(2021, 1, 1).rfc3339

  before_validation :set_defaults

  store_accessor :raw, :updated_at, prefix: true
  store_accessor :raw, :meta
  store_accessor :raw, :data

  validates :raw, presence: true
  validates :tx_id, uniqueness: true
  validates :block_num, uniqueness: true
  validates :transation_id, uniqueness: true

  def self.poll_authorizations
    loop do
      polled_at = PrsTransaction.order(created_at: :desc).first&.raw_updated_at || POLLING_START_TIME
      r = Prs.api.pip2001_authorization(count: 50, updated_at: polled_at)

      authorizations = r&.[]('data')&.[]('authorization')
      break if authorizations.blank?

      authorizations.each do |authorization|
        tx = PrsTransaction.create_with(raw: authorization).find_or_create_by(tx_id: authorization['id'])
        tx.update raw: authorization if tx.block_num.blank?
      end

      break if authorizations.length < 50

      sleep POLLING_INTERVAL
    end
  end

  def self.poll_posts
    loop do
      polled_at = PrsTransaction.order(created_at: :desc).first&.raw_updated_at || POLLING_START_TIME
      r = Prs.api.pip2001_posts(count: 50, updated_at: polled_at)

      posts = r&.[]('data')&.[]('posts')
      break if posts.blank?

      posts.each do |post|
        tx = PrsTransaction.create_with(raw: post).find_or_create_by(tx_id: post['id'])
        tx.update raw: post if tx.block_num.blank?
      end

      break if posts.length < 50

      sleep POLLING_INTERVAL
    end
  end

  private

  def set_defaults
    return if raw.blank?

    assign_attributes(
      tx_id: raw['id'],
      block_type: raw['type'],
      hash_str: raw['hash'],
      signature: raw['signature'],
      user_address: raw['user_address'],
      block_num: raw['block_num']
    )

    return unless data.is_a?(Hash)

    self.type = 'PrsAccountAllowTransaction' if data.key?('allow')
    self.type = 'PrsAccountDenyTransaction' if data.key?('deny')
    self.type = 'ArticlePrsTransaction' if data.key?('file_hash')
  end
end
