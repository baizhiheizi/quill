# frozen_string_literal: true

module Resolvers
  class AdminPrsTransactionConnectionResolver < AdminBaseResolver
    argument :type, String, required: false
    argument :after, String, required: false

    type Types::PrsTransactionType.connection_type, null: false

    def resolve(**params)
      transactions =
        case params[:type]
        when 'PrsAccountAuthorizationTransaction'
          PrsAccountAuthorizationTransaction.all
        when 'ArticleSnapshotPrsTransaction'
          ArticleSnapshotPrsTransaction.all
        else
          PrsTransaction.all
        end

      transactions.order(created_at: :desc)
    end
  end
end
