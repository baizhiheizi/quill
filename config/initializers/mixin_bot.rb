# frozen_string_literal: true

MixinBot.scope = Rails.application.credentials.dig(:mixin, :scope)
MixinBot.api_host = 'mixin-api.zeromesh.net' if Rails.env.development?
MixinBot.blaze_host = 'mixin-blaze.zeromesh.net' if Rails.env.development?
