# frozen_string_literal: true

module Types
  class PaymentConnectionType < Types::BaseConnection
    edge_type(Types::PaymentType.edge_type)
  end
end
