# frozen_string_literal: true

# == Schema Information
#
# Table name: arweave_transactions
#
#  id                  :bigint           not null, primary key
#  article_uuid        :uuid
#  hash                :string
#  raw                 :json
#  state               :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  article_snapshot_id :bigint
#  order_id            :bigint
#  owner_id            :uuid
#  tx_id               :string
#
# Indexes
#
#  index_arweave_transactions_on_article_snapshot_id    (article_snapshot_id)
#  index_arweave_transactions_on_article_uuid_and_hash  (article_uuid,hash) UNIQUE
#  index_arweave_transactions_on_order_id               (order_id)
#  index_arweave_transactions_on_owner_id               (owner_id)
#  index_arweave_transactions_on_tx_id                  (tx_id)
#
class ArweaveTransaction < ApplicationRecord
  include AASM

  belongs_to :order, optional: true
  belongs_to :owner, class_name: 'User', primary_key: :mixin_uuid, inverse_of: :arweave_transactions, optional: true
  belongs_to :article, primary_key: :uuid, foreign_key: :article_uuid, inverse_of: :arweave_transactions
  belongs_to :article_snapshot

  before_validation :setup_attributes, on: :create
  validates :tx_id, presence: true
  validates :raw, presence: true

  aasm column: :state do
    state :pending, initial: true
    state :accepted

    event :accept, guard: :accepted_by_arweave? do
      transitions from: :pending, to: :accepted
    end
  end

  def self.wallet
    return if ENV['ARWEAVE_KEYSTORE_FILE'].blank?

    @wallet ||= Arweave::Wallet.new JSON.parse File.read(ENV.fetch('ARWEAVE_KEYSTORE_FILE'))
  rescue StandardError
    nil
  end

  def status
    Arweave::Transaction.status tx_id
  end

  def accepted_by_arweave?
    status.accepted?
  end

  def data
    @data ||=
      begin
        JSON.parse Arweave::Transaction.data(tx_id)
      rescue ParseError
        {}
      end
  end

  def artx
    Arweave::Transaction.new raw
  end

  def generated_data
    if article.free?
      {
        content: {
          title: article_snapshot.raw['title'],
          intro: article_snapshot.raw['intro'],
          body: article_snapshot.raw['content']
        },
        hash: hash,
        author: article.author.uid,
        original_url: user_article_url(article.author, article),
        timestamp: article_snapshot.created_at.to_i
      }
    else
      encrypted_data
    end
  end

  def encrypted_data
    if owner&.public_key.present?
      encrypted_data_for_owner
    else
      encrypter = OpenSSL::Cipher.new('aes-256-cfb').encrypt
      iv = encrypter.random_iv
      encrypter.iv = iv
      encrypter.key = Base64.urlsafe_decode64 Rails.application.credentials.dig(:encryption, :aes_key)
      cipher = encrypter.update(article_snapshot.raw['content']) + encrypter.final

      {
        content: {
          title: article_snapshot.raw['title'],
          intro: article_snapshot.raw['intro'],
          body: Base64.urlsafe_encode64(cipher, padding: false)
        },
        hash: hash,
        alg: {
          name: 'aes-256-cfb',
          iv: Base64.urlsafe_encode64(iv, padding: false)
        },
        author: article.author.uid,
        original_url: user_article_url(article.author, article),
        timestamp: article_snapshot.created_at.to_i
      }
    end
  end

  def encrypted_data_for_owner
    return if owner&.public_key.blank?

    ec = OpenSSL::PKey::EC.new 'secp256k1'
    group = OpenSSL::PKey::EC::Group.new 'secp256k1'
    ec.private_key = OpenSSL::BN.new(Rails.application.credentials.dig(:encryption, :private_key).to_i(16))
    ec.public_key =  group.generator.mul ec.private_key

    owner_public_key =
      OpenSSL::PKey::EC::Point.new(
        group,
        OpenSSL::BN.new(owner.public_key.to_i(16))
      )

    encrypter = OpenSSL::Cipher.new('aes-256-cfb').encrypt
    key = ec.dh_compute_key owner_public_key
    iv = encrypter.random_iv
    encrypter.iv = iv
    encrypter.key = key
    cipher = encrypter.update(article_snapshot.raw['content']) + encrypter.final

    {
      content: {
        title: article_snapshot.raw['title'],
        intro: article_snapshot.raw['intro'],
        body: Base64.urlsafe_encode64(cipher, padding: false)
      },
      hash: hash,
      alg: {
        name: 'aes-256-cfb',
        iv: Base64.urlsafe_encode64(iv, padding: false),
        public_key: ec.public_key.to_bn.to_fs(16).downcase
      },
      author: article.author.uid,
      owner: owner.uid,
      original_url: user_article_url(article.author, article),
      timestamp: article_snapshot.created_at.to_i
    }
  end

  def snapshot_url
    @snapshot_url ||=
      Addressable::URI.new(
        scheme: 'https',
        host: 'v2.viewblock.io',
        path: "arweave/tx/#{tx_id}"
      ).to_s
  end

  private

  def setup_attributes
    return unless new_record?
    return unless encryptable?

    self.hash = SHA3::Digest::SHA256.hexdigest article_snapshot.raw['content']
    tx = Arweave::Transaction.new data: generated_data.to_json
    tags.each do |tag|
      next if tag[:value].blank?

      tx.add_tag name: tag[:name], value: tag[:value]
    end
    tx.sign self.class.wallet
    tx.commit
    self.raw = tx.attributes
    self.tx_id = tx.attributes[:id]
  end

  def encryptable?
    return false if self.class.wallet.blank?
    return false if Rails.application.credentials.dig(:encryption, :private_key).blank?

    true
  end

  def tags
    [
      {
        name: 'Content-Type',
        value: 'application/json'
      },
      {
        name: 'App-Name',
        value: 'quill.im'
      },
      {
        name: 'Owner',
        value: (owner&.public_key.present? ? owner.uid : nil)
      },
      {
        name: 'Author',
        value: article.author.uid
      },
      {
        name: 'Content-Digest',
        value: hash
      },
      {
        name: 'UUID',
        value: article.uuid
      },
      {
        name: 'Collection-ID',
        value: article.collection&.uuid
      }
    ]
  end
end
