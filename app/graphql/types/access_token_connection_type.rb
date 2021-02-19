# frozen_string_literal: true

module Types
  class AccessTokenConnectionType < Types::BaseConnection
    edge_type(Types::AccessTokenType.edge_type)
  end
end
