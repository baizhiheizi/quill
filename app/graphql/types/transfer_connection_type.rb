# frozen_string_literal: true

module Types
  class TransferConnectionType < Types::BaseConnection
    edge_type(Types::TransferType.edge_type)
  end
end
