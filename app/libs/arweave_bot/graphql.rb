# frozen_string_literal: true

require 'graphql/client/http'

module ArweaveBot
  class Graphql
    http = GraphQL::Client::HTTP.new('https://arweave.net/graphql')
    Schema = GraphQL::Client.load_schema(http)
    Client = GraphQL::Client.new(schema: Schema, execute: http)

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
    def mirror_transactions(contributor, digest: '', after: '', first: 100)
      Client.query(MirrorTransactionsQuery, variables: { contributor: contributor, digest: digest, after: after, first: first })
    end

    def all_mirror_transactions(contributor)
      ids = []
      has_next_page = true
      after = ''

      while has_next_page
        r = mirror_transactions(contributor, after: after).data.transactions
        ids += r.edges.map(&->(tx) { tx.node.id })
        after = r.edges.last&.cursor
        has_next_page = r.page_info.has_next_page
      end

      ids
    end
  end
end
