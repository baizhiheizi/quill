# frozen_string_literal: true

module Types
  class UserAccessTokenConnectionType < Types::BaseConnection
    edge_type(Types::UserAccessTokenType.edge_type)
  end
end
