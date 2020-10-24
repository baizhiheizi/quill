# frozen_string_literal: true

module Types
  class ArticleConnectionType < Types::BaseConnection
    edge_type(Types::ArticleType.edge_type)
  end
end
