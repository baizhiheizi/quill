# frozen_string_literal: true

module Global
  class << self
    attr_accessor :redis
  end
end
redis = Redis::Namespace.new(Rails.application.credentials.dig(:redis, :namespace), redis: Redis.new)

Global.redis = redis
Redis::Objects.redis = redis
Redis.exists_returns_integer = true
