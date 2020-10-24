# frozen_string_literal: true

module Connections
  class OrderConnectionType < Types::BaseConnection
    edge_type(Types::OrderType.edge_type)
  end
end
