# frozen_string_literal: true

module Authenticatable
  extend ActiveSupport::Concern

  class_methods do
    def auth_from_mixin(code)
      token = QuillBot.api.oauth_token code
      res = QuillBot.api.read_me access_token: token
      raise res.inspect if res['error'].present?

      auth = UserAuthorization.create_with(
        raw: res['data'],
        access_token: token
      ).find_or_create_by!(
        uid: res['data'].fetch('user_id'),
        provider: :mixin
      )
      raw = (auth.raw.presence || {}).merge(res['data'])
      auth.update raw: raw, access_token: token

      find_or_create_user_by_auth auth
    end

    def auth_from_fennec(token)
      res = QuillBot.api.read_me access_token: token
      raise res.inspect if res['error'].present?

      auth = UserAuthorization.create_with(
        raw: res['data'],
        access_token: token
      ).find_or_create_by!(
        uid: res['data'].fetch('user_id'),
        provider: :fennec
      )
      raw = (auth.raw.presence || {}).merge(res['data'])
      auth.raw = raw
      auth.update! raw: raw if auth.raw_changed?

      find_or_create_user_by_auth auth
    end

    def auth_from_mvm_eth(address, signature)
      msg = Rails.cache.read address
      Rails.cache.delete address

      return if msg.blank?
      return unless Eth::Signature.verify msg, signature, address

      public_key = Eth::Signature.personal_recover msg, signature

      res = MVM.bridge.user address
      return if res.blank?

      auth = UserAuthorization.create_with(
        raw: res['user'],
        public_key: public_key
      ).find_or_create_by!(
        uid: address,
        provider: :mvm_eth
      )
      auth.update! raw: res['user'], public_key: public_key

      user = find_or_create_user_by_auth auth
      session_id = JSON.parse(msg)['session']

      [user, session_id]
    end

    private

    def find_or_create_user_by_auth(auth)
      if auth.user.present?
        user = auth.user
        if user.messenger?
          user.update(
            name: auth.name,
            biography: auth.biography
          )
        end
      else
        user = create!(
          avatar_url: auth.raw['avatar_url'],
          name: auth.raw['full_name'],
          biography: auth.raw['biography'],
          mixin_id: auth.raw['identity_number'] || '0',
          mixin_uuid: auth.raw['user_id'],
          uid: auth.mixin? ? auth.raw['identity_number'] : auth.uid.gsub('-', '')
        )
        auth.update user: user
      end

      user
    end
  end
end
