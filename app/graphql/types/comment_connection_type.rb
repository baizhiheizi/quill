# frozen_string_literal: true

module Types
  class CommentConnectionType < Types::BaseConnection
    edge_type(Types::CommentType.edge_type)
  end
end
