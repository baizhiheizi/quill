# frozen_string_literal: true

module Types
  class MixinMessageConnectionType < Types::BaseConnection
    edge_type(Types::MixinMessageType.edge_type)
  end
end
