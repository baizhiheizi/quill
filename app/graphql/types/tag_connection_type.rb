# frozen_string_literal: true

module Types
  class TagConnectionType < Types::BaseConnection
    edge_type(Types::TagType.edge_type)
  end
end
