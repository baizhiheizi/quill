# frozen_string_literal: true

# == Schema Information
#
# Table name: collectibles
#
#  id            :bigint           not null, primary key
#  identifier    :string
#  metadata      :jsonb
#  metahash      :string
#  name          :string
#  source_type   :string
#  state         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  collection_id :uuid
#  source_id     :bigint
#  token_id      :uuid
#
# Indexes
#
#  index_collectibles_on_collection_id_and_identifier  (collection_id,identifier) UNIQUE
#  index_collectibles_on_metahash                      (metahash) UNIQUE
#  index_collectibles_on_source_type_and_source_id     (source_type,source_id) UNIQUE
#  index_collectibles_on_token_id                      (token_id) UNIQUE
#
class Collectible < ApplicationRecord
  MINT_ASSET_ID = 'c94ac88f-4671-3976-b60a-09064f1811e8'
  MINT_FEE = 0.001

  include AASM

  belongs_to :source, polymorphic: true, optional: true
  belongs_to :collection, primary_key: :uuid, optional: true
  belongs_to :nft_collection, primary_key: :uuid, foreign_key: :collection_id, optional: true, inverse_of: :collectibles

  has_many :non_fungible_outputs, primary_key: :token_id, foreign_key: :token_id, dependent: :restrict_with_exception, inverse_of: :collectible
  has_many :transfers, as: :source, dependent: :restrict_with_exception

  has_one_attached :media

  before_validation :setup_default_attributes, on: :create

  validates :identifier, presence: true
  validates :name, presence: true
  validates :metahash, presence: true
  validates :collection_id, presence: true

  aasm column: :state do
    state :pending, initial: true
    state :minted

    event :mint, guards: :nfo_existed? do
      transitions from: :pending, to: :minted
    end
  end

  def transfer_to_owner_async
    CollectibleTransferToOwnerWorker.perform_async id
  end

  def transfer_to_owner
    Trident.api.transfer collection_id, identifier, source.buyer.mixin_uuid
    source.buyer.sync_collectibles!
  end

  def mint_async
    CollectibleMintWorker.perform_async id
  end

  def do_mint!
    return unless pending?
    return if nfo_existed?

    Trident.api.upload_metadata metadata: metadata, metahash: metahash

    transfers.create_with(
      wallet: QuillBot.api.client_id,
      transfer_type: :mint_nft,
      queue_priority: :default,
      opponent_multisig: {
        receivers: TridentAssistant::Utils::NFO_MTG[:members],
        threshold: TridentAssistant::Utils::NFO_MTG[:threshold]
      },
      asset_id: MINT_ASSET_ID,
      amount: MINT_FEE,
      memo: mint_memo
    ).find_or_create_by!(
      trace_id: QuillBot.api.unique_uuid(
        source.trace_id,
        generated_token_id
      )
    )
  end

  def collection_id_valid?
    collection_id != '00000000-0000-0000-0000-000000000000'
  end

  def trident_url
    Addressable::URI.new(
      scheme: 'https',
      host: 'thetrident.one',
      path: "collectibles/#{metahash}"
    ).to_s
  end

  def media_url
    return unless media.attached?

    [Settings.storage.endpoint, media.key].join('/')
  end

  def mint_memo
    @mint_memo ||=
      QuillBot.api.nft_memo collection_id, identifier, metahash
  end

  def nfo_existed?
    QuillBot.api.collectible generated_token_id
  rescue MixinBot::NotFoundError
    false
  end

  def generated_token_id
    @generated_token_id ||= MixinBot::Utils::Nfo.new(collection: collection_id, token: identifier).unique_token_id
  end

  private

  def setup_default_attributes
    return if token_id.blank?

    r = QuillBot.api.collectible token_id
    group =
      if r['group'].present?
        begin
          MixinBot::Utils::UUID.new(hex: r['group']).unpacked
        rescue MixinBot::InvalidUuidFormatError
          ''
        end
      end

    assign_attributes(
      identifier: r['token'],
      collection_id: group,
      metahash: r['meta']['hash'],
      name: r['meta']['name'],
      metadata: r['meta']
    )

    self.nft_collection = NftCollection.find_or_create_by(uuid: collection_id) if collection_id_valid?
  end
end
