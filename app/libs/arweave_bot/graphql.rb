# frozen_string_literal: true

require 'graphql/client/http'

module ArweaveBot
  class Graphql
    HTTP = GraphQL::Client::HTTP.new('https://arweave.net/graphql')
    Schema = GraphQL::Client.load_schema(HTTP)
    Client = GraphQL::Client.new(schema: Schema, execute: HTTP)

    MirrorTransactionsQuery = Client.parse <<~GRAPHQL
      query($contributor: String!, $digest: String!, $after: String, $first: Int) {
        transactions(
          tags: [
            { name: "Content-Type", values: "application/json" }
            { name: "App-Name", values: ["MirrorXYZ"] }
            { name: "Contributor", values: [$contributor] }
            {
              name: "Original-Content-Digest"
              values: [$digest]
            }
          ]
          after: $after
          first: $first
        ) {
          pageInfo {
            hasNextPage
          }
          edges {
            cursor
            node {
              id
            }
          }
        }
      }
    GRAPHQL
    def mirror_transactions(contributor, digest: '', after: '', first: 10)
      Client.query(MirrorTransactionsQuery, variables: { contributor: contributor, digest: digest, after: after, first: first })
    end
  end
end
