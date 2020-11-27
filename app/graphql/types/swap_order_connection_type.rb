# frozen_string_literal: true

module Types
  class SwapOrderConnectionType < Types::BaseConnection
    edge_type(Types::SwapOrderType.edge_type)
  end
end
