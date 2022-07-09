# frozen_string_literal: true

module Authenticatable
  extend ActiveSupport::Concern

  class_methods do
    def auth_from_mixin(code)
      token = BatataBot.api.oauth_token code
      res = BatataBot.api.read_me access_token: token
      raise res.inspect if res['error'].present?

      auth = UserAuthorization.create_with(
        raw: res['data'],
        access_token: token
      ).find_or_create_by!(
        uid: res['data'].fetch('user_id'),
        provider: :mixin
      )
      raw = (auth.raw.presence || {}).merge(res['data'])
      auth.raw = raw
      auth.update! raw: raw if auth.raw_changed?

      find_or_create_user_by_auth auth
    end

    def auth_from_fennec(token)
      res = BatataBot.api.read_me access_token: token
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

    def auth_from_mvm_eth(public_key, signature)
      msg = Global.redis.get public_key
      Global.redis.del public_key

      return if msg.blank?
      return unless Eth::Signature.verify msg, signature, public_key

      res = MVM.api.user public_key
      return if res.blank?

      auth = UserAuthorization.create_with(
        raw: res['user']
      ).find_or_create_by!(
        uid: public_key,
        provider: :mvm_eth
      )
      auth.raw = res['user']
      auth.update! raw: res['user'] if auth.raw_changed?

      find_or_create_user_by_auth auth
    end

    private

    def find_or_create_user_by_auth(auth)
      if auth.user.present?
        user = auth.user
        user.update_profile auth.raw
      else
        user = create!(
          avatar_url: auth.raw['avatar_url'],
          name: auth.raw['full_name'],
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
