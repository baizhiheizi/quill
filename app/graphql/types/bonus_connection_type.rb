# frozen_string_literal: true

module Types
  class BonusConnectionType < Types::BaseConnection
    edge_type(Types::BonusType.edge_type)
  end
end
