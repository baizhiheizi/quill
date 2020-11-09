# frozen_string_literal: true

module Resolvers
  class AdminMixinMessageConnectionResolver < AdminBaseResolver
    argument :after, String, required: false

    type Types::MixinMessageConnectionType, null: false

    def resolve(_params = {})
      MixinMessage.where.not(category: 'SYSTEM_ACCOUNT_SNAPSHOT').order(created_at: :desc)
    end
  end
end
