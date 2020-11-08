# frozen_string_literal: true

class PrsdiggSchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)

  # Opt in to the new runtime (default in future graphql-ruby versions)
  use GraphQL::Execution::Interpreter
  use GraphQL::Analysis::AST

  # Add built-in connections for pagination
  use GraphQL::Pagination::Connections
  default_max_page_size 20

  # use batch loader to fix N+1
  use BatchLoader::GraphQL
end
