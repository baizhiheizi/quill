# frozen_string_literal: true

class PrsdiggSchema < GraphQL::Schema
  mutation Types::MutationType
  query Types::QueryType

  default_max_page_size 20

  # use batch loader to fix N+1
  use BatchLoader::GraphQL
end
