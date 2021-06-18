# frozen_string_literal: true

module Types
  class PrsTransactionType < Types::BaseObject
    field :id, ID, null: false
    field :type, String, null: true
    field :block_num, Integer, null: false
    field :block_type, String, null: false
    field :hash_str, String, null: false
    field :signature, String, null: false
    field :user_address, String, null: false
    field :transaction_id, String, null: true
    field :tx_id, String, null: false
    field :data, String, null: true
    field :processed_at, GraphQL::Types::ISO8601DateTime, null: true

    field :prs_account, Types::PrsAccountType, null: true

    def prs_account
      BatchLoader::GraphQL.for(object.user_address).batch do |user_addresses, loader|
        PrsAccount.where(account: user_addresses).each { |user| loader.call(user.account, user) }
      end
    end
  end
end
