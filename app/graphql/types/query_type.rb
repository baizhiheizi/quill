# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :article_connection, resolver: Resolvers::ArticleConnectionResolver
    field :article, resolver: Resolvers::ArticleResolver
    field :comment_connection, resolver: Resolvers::CommentConnectionResolver
    field :transfer_connection, resolver: Resolvers::TransferConnectionResolver
    field :statistics, resolver: Resolvers::StatisticsResolver

    field :user, resolver: Resolvers::UserResolver
    field :user_article_connection, resolver: Resolvers::UserArticleConnectionResolver

    field :my_article_connection, resolver: Resolvers::MyArticleConnectionResolver
    field :my_payment_connection, resolver: Resolvers::MyPaymentConnectionResolver
    field :my_transfer_connection, resolver: Resolvers::MyTransferConnectionResolver

    # admin
    field :admin_article_connection, resolver: Resolvers::AdminArticleConnectionResolver
    field :admin_comment_connection, resolver: Resolvers::AdminCommentConnectionResolver
    field :admin_user_connection, resolver: Resolvers::AdminUserConnectionResolver
    field :admin_payment_connection, resolver: Resolvers::AdminPaymentConnectionResolver
    field :admin_transfer_connection, resolver: Resolvers::AdminTransferConnectionResolver
    field :admin_announcement_connection, resolver: Resolvers::AdminAnnouncementConnectionResolver
    field :admin_mixin_message_connection, resolver: Resolvers::AdminMixinMessageConnectionResolver
  end
end
