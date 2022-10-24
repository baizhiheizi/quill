# frozen_string_literal: true

module Users::CollectibleReadable
  extend ActiveSupport::Concern

  def mixin_access_token
    @mixin_access_token = authorization&.access_token
  end

  def collectible_readable?
    return if mixin_access_token.blank?

    r = QuillBot.api.collectibles access_token: mixin_access_token

    r['error'].blank?
  rescue MixinBot::UnauthorizedError, MixinBot::ForbiddenError => e
    raise e if Rails.env.development?

    false
  end

  def mixin_api_collectibles(offset: nil)
    QuillBot
      .api
      .collectibles(
        members: [mixin_uuid],
        threshold: 1,
        offset: offset,
        limit: 500,
        access_token: mixin_access_token
      )
  end

  def owner_of_collection?(collection_id)
    if messenger?
      sync_collectibles!
      collectibles.where(collection_id: collection_id).present?
    elsif mvm_eth?
      contract = MVM.nft.contract_from_collection collection_id
      MVM.scan.tokens(uid, type: 'ERC-721').filter(&->(token) { token['contractAddress'].downcase == contract.downcase }).present?
    end
  rescue StandardError => e
    Rails.logger.error e
    false
  end

  def sync_collectibles!(restart: false)
    return unless messenger?

    offset =
      if restart
        ''
      else
        non_fungible_outputs.first&.raw&.[]('updated_at')
      end

    loop do
      logger.info "=== Syncing #{name}(#{id}) collectibles since #{offset}"
      r = mixin_api_collectibles offset: offset

      logger.info "=== found #{r['data'].size} collectibles"
      r['data'].each do |c|
        logger.info "=== processing collectible output_id=#{c['output_id']} token_id=#{c['token_id']}"
        nfo = NonFungibleOutput.find_by("raw->>'output_id' = ?", c['output_id'])
        if nfo.present?
          nfo.update! raw: c
        else
          token = QuillBot.api.collectible c['token_id']
          collectible = Collectible.find_by metahash: token.dig('meta', 'hash')
          if collectible.blank?
            Collectible.find_or_create_by! token_id: c['token_id']
          else
            collectible.update! token_id: c['token_id']
            collectible.mint! if collectible.pending?
          end
          non_fungible_outputs.create! raw: c
        end
      end

      offset = r['data'].last['updated_at'] if r['data'].size.positive?
      if r['data'].size < 500
        logger.info "#{name}(#{id}) collectibles synced"
        break
      end
    end
    true
  rescue MixinBot::HttpError
    retry
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
    Rails.logger.error e
    false
  end
end
