# frozen_string_literal: true

module Orders::Mintable
  DEFAULT_ROYALTY = '0.05'

  def may_mint?
    return false if collectible.present?

    item.is_a?(Collection) && completed?
  end

  def minted?
    collectible&.minted?
  end

  def mint!
    return unless may_mint?

    _collectible = Collectible.new

    identifier = item.collectibles.count + 1

    media = URI.parse(item.generated_collectible_media_url(identifier)).open
    _collectible.media.attach io: media, filename: "#{identifier}.png"
    media_hash = SHA3::Digest::SHA256.hexdigest media.read

    metadata =
      TridentAssistant::Utils::Metadata.new(
        creator: {
          id: QuillBot.api.client_id,
          name: 'Quill',
          royalty: DEFAULT_ROYALTY
        },
        collection: {
          id: item.uuid,
          name: item.name,
          symbol: item.symbol,
          description: item.description,
          icon: {
            url: item.cover_url
          },
          split: Collection::DEFAULT_SPLIT
        },
        token: {
          id: identifier.to_s,
          name: "##{identifier}",
          description: "#{item.name} ##{identifier}",
          icon: {
            url: _collectible.media_url
          },
          media: {
            url: _collectible.media_url,
            hash: media_hash
          },
          attributes: {
            author: item.author.uid
          }
        },
        checksum: {
          fields: [
            'creator.id',
            'creator.royalty',
            'collection.id',
            'collection.name',
            'collection.symbol',
            'collection.split',
            'token.id',
            'token.name',
            'token.media.hash',
            'token.attributes.author'
          ],
          algorithm: 'sha256'
        }
      )

    _collectible.assign_attributes(
      source: self,
      collection_id: item.uuid,
      identifier: identifier,
      name: "##{identifier}",
      metadata: metadata.json,
      metahash: SHA3::Digest::SHA256.hexdigest(metadata.checksum_content)
    )
    ActiveRecord::Base.transaction do
      _collectible.save!
      payment.complete! if payment.may_complete?
    end
    _collectible.mint_async
  end
end
