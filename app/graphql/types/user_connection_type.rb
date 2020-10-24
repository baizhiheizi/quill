# frozen_string_literal: true

module Connections
  class UserConnectionType < Types::BaseConnection
    edge_type(Types::UserType.edge_type)
  end
end
