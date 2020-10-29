# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :article_connection, resolver: Resolvers::ArticleConnectionResolver
    field :article, resolver: Resolvers::ArticleResolver
    field :comment_connection, resolver: Resolvers::CommentConnectionResolver

    field :my_article_connection, resolver: Resolvers::MyArticleConnectionResolver
    field :my_payment_connection, resolver: Resolvers::MyPaymentConnectionResolver
    field :my_transfer_connection, resolver: Resolvers::MyTransferConnectionResolver
  end
end
