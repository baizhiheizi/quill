# frozen_string_literal: true

require 'graphql/client/http'

module ArweaveBot
  class Graphql
    http = GraphQL::Client::HTTP.new('https://arweave.net/graphql')
    Schema = GraphQL::Client.load_schema(http)
    Client = GraphQL::Client.new(schema: Schema, execute: http)

    MirrorTransactionsQuery = Client.parse <<~GRAPHQL
      query($contributor: String!, $after: String, $first: Int) {
        transactions(
          tags: [
            { name: "Content-Type", values: "application/json" }
            { name: "App-Name", values: ["MirrorXYZ"] }
            { name: "Contributor", values: [$contributor] }
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
              tags {
                name
                value
              }
            }
          }
        }
      }
    GRAPHQL
    def mirror_transactions(contributor, after: '', first: 100)
      Client.query(MirrorTransactionsQuery, variables: { contributor:, after:, first: })
    end

    def all_mirror_transactions(contributor)
      txs = []
      has_next_page = true
      after = ''

      while has_next_page
        r = mirror_transactions(contributor, after:).data.transactions
        r.edges.each do |tx|
          puts tx
          txs << {
            id: tx.node.id,
            digest: tx.node.tags.find(&->(tag) { tag.name == 'Original-Content-Digest' }).value
          }
        end
        after = r.edges.last&.cursor
        has_next_page = r.page_info.has_next_page
      end

      txs
    end
  end
end
