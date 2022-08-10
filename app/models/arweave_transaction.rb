# frozen_string_literal: true

# == Schema Information
#
# Table name: arweave_transactions
#
#  id                  :bigint           not null, primary key
#  article_uuid        :uuid
#  raw                 :json
#  state               :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  article_snapshot_id :bigint
#  order_id            :bigint
#  signer_id           :uuid
#  tx_id               :string
#
# Indexes
#
#  index_arweave_transactions_on_article_snapshot_id  (article_snapshot_id)
#  index_arweave_transactions_on_article_uuid         (article_uuid)
#  index_arweave_transactions_on_order_id             (order_id)
#  index_arweave_transactions_on_signer_id            (signer_id)
#  index_arweave_transactions_on_tx_id                (tx_id)
#
class ArweaveTransaction < ApplicationRecord
  include AASM

  belongs_to :order, optional: true
  belongs_to :signer, class_name: 'User', primary_key: :mixin_uuid, inverse_of: :arweave_transactions
  belongs_to :article, primary_key: :uuid, foreign_key: :article_uuid, inverse_of: :arweave_transactions
  belongs_to :article_snapshot

  before_validation :setup_attributes
  validate :ensuere_user_encryptable

  aasm column: :state do
    state :pending, initial: true
    state :accepted

    event :accept, guard: :accepted_by_arweave? do
      transitions from: :pending, to: :accepted
    end
  end

  def self.wallet
    return if ENV['ARWEAVE_KEYSTORE_FILE'].blank?

    @wallet ||= Arweave::Wallet.new JSON.parse(File.read(ENV.fetch('ARWEAVE_KEYSTORE_FILE', nil)))
  rescue StandardError
    nil
  end

  def status
    Arweave::Transaction.status tx_id
  end

  def accepted_by_arweave?
    status.accepted?
  end

  def tx
    Arweave::Transaction.new raw
  end

  def tags
    [
      {
        name: 'Content-Type',
        value: 'application/json'
      },
      {
        name: 'App-Name',
        value: 'Quill'
      },
      {
        name: 'Signer-Address',
        value: signer.uid
      }
    ]
  end

  def original_data
    {
      title: article.title,
      intro: article.intro,
      conent: article_snapshot.raw['content'],
      author: article.author.uid,
      version: article_snapshot.created_at.to_i
    }
  end

  def snapshot_url
    Addressable::URI.new(
      scheme: 'https',
      host: 'viewblock.io',
      path: "arweave/tx/#{tx_id}"
    ).to_s
  end

  private

  def setup_attributes
    tx = Arweave::Transaction.new data: original_data.to_json
    tx.sign ArweaveTransaction.wallet
    tags.each do |tag|
      tx.add_tag name: tag[:name], value: tag[:value]
    end
    tx.commit
    self.raw = tx.attributes
    self.tx_id = tx.attributes[:id]
  end

  def ensuere_user_encryptable
    errors.add(:signer, 'not valid') unless signer.mvm_eth?
  end
end
