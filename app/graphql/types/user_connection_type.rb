# frozen_string_literal: true

module Types
  class UserConnectionType < Types::BaseConnection
    edge_type(Types::UserType.edge_type)
  end
end
