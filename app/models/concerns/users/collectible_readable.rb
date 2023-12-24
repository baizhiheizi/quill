# frozen_string_literal: true

module Users::CollectibleReadable
  extend ActiveSupport::Concern

  def owning_collections
    @owning_collections ||= NftCollection.where(uuid: owning_collection_ids)
  end

  def owning_collection_ids
    sync_collectibles_async
    @owning_collection_ids ||=
      if messenger?
        collectibles.pluck(:collection_id).uniq.compact
      elsif mvm_eth?
        Rails.cache.fetch "#{uid}_nft_collections_ids", expires_in: 3.minutes do
          tokens_erc721.map(&->(token) { MVM.nft.collection_from_contract(token['contractAddress']) }).compact
        end
      else
        []
      end
  rescue StandardError => e
    Rails.logger.error e
    []
  end

  def owning_collectibles
    @owning_collectibles ||=
      if messenger?
        collectibles
      elsif mvm_eth?
        ids =
          Rails.cache.fetch "#{uid}_collectible_token_ids", expires_in: 3.minutes do
            token_ids = []
            tokens_erc721.each do |token|
              token['balance'].to_i.times do |index|
                collection_id = MVM.nft.collection_from_contract token['contractAddress']
                identifier = MVM.nft.token_of_owner_by_index token['contractAddress'], uid, index
                token_ids << MixinBot::Utils::Nfo.new(collection: collection_id, token: identifier.to_i).unique_token_id
              end
            end

            token_ids
          end
        Collectible.where(token_id: ids)
      else
        []
      end
  rescue StandardError => e
    Rails.logger.error e
    Collectible.none
  end

  def mixin_access_token
    @mixin_access_token = authorization&.access_token
  end

  def collectible_readable?
    return false if mixin_access_token.blank?

    r = QuillBot.api.collectibles access_token: mixin_access_token

    r['error'].blank?
  rescue MixinBot::UnauthorizedError, MixinBot::ForbiddenError => e
    raise e if Rails.env.development?

    false
  end

  def mixin_api_collectibles(offset: nil)
    api =
      if messenger?
        QuillBot.api
      elsif mvm_eth?
        authorization.mixin_api
      end

    api.collectibles(
      members: [mixin_uuid],
      threshold: 1,
      offset: offset,
      limit: 500,
      access_token: mixin_access_token
    )
  end

  def sync_collectibles_async
    return unless should_sync_collectibles?

    Users::SyncCollectiblesJob.perform_later id
  end

  def should_sync_collectibles?
    return false unless messenger? || mvm_eth?
    return false unless collectible_readable?

    last_sync_at = Rails.cache.read("#{mixin_uuid}_last_sync_collectibles_at")
    return true if last_sync_at.blank?

    last_sync_at < 30.seconds.ago
  end

  def sync_collectibles!(restart: false)
    return unless messenger? || mvm_eth?

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
          # igonore invalid output
          next if token.dig('meta', 'hash').blank?

          collectible = Collectible.find_by metahash: token.dig('meta', 'hash')
          if collectible.blank?
            Collectible.create_with(state: :minted).find_or_create_by! token_id: c['token_id']
          else
            collectible.update! token_id: c['token_id'], state: :minted
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
  rescue ActiveRecord::RecordNotUnique,
         ActiveRecord::RecordInvalid,
         MixinBot::UnauthorizedError,
         MixinBot::ForbiddenError => e
    Rails.logger.error e
    false
  ensure
    Rails.cache.write "#{mixin_uuid}_last_sync_collectibles_at", Time.current
  end
end
