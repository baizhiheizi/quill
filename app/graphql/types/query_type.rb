# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :article_connection, resolver: Resolvers::ArticleConnectionResolver
    field :article, resolver: Resolvers::ArticleResolver
    field :comment_connection, resolver: Resolvers::CommentConnectionResolver
    field :transfer_connection, resolver: Resolvers::TransferConnectionResolver

    field :statistics, resolver: Resolvers::StatisticsResolver
    field :user_chart, resolver: Resolvers::UserChartResolver
    field :article_chart, resolver: Resolvers::ArticleChartResolver
    field :revenue_chart, resolver: Resolvers::RevenueChartResolver

    field :user, resolver: Resolvers::UserResolver
    field :user_article_connection, resolver: Resolvers::UserArticleConnectionResolver

    field :swap_pre_order, resolver: Resolvers::SwapPreOrderResolver
    field :payment, resolver: Resolvers::PaymentResolver

    field :my_article, resolver: Resolvers::MyArticleResolver
    field :my_article_order_connection, resolver: Resolvers::MyArticleOrderConnectionResolver
    field :my_article_connection, resolver: Resolvers::MyArticleConnectionResolver
    field :my_payment_connection, resolver: Resolvers::MyPaymentConnectionResolver
    field :my_transfer_connection, resolver: Resolvers::MyTransferConnectionResolver
    field :my_swap_order_connection, resolver: Resolvers::MySwapOrderConnectionResolver
    field :my_statistics, resolver: Resolvers::MyStatisticsResolver

    # admin
    field :admin_article_connection, resolver: Resolvers::AdminArticleConnectionResolver
    field :admin_comment_connection, resolver: Resolvers::AdminCommentConnectionResolver
    field :admin_user_connection, resolver: Resolvers::AdminUserConnectionResolver
    field :admin_order_connection, resolver: Resolvers::AdminOrderConnectionResolver
    field :admin_swap_order_connection, resolver: Resolvers::AdminSwapOrderConnectionResolver
    field :admin_payment_connection, resolver: Resolvers::AdminPaymentConnectionResolver
    field :admin_transfer_connection, resolver: Resolvers::AdminTransferConnectionResolver
    field :admin_announcement_connection, resolver: Resolvers::AdminAnnouncementConnectionResolver
    field :admin_bonus_connection, resolver: Resolvers::AdminBonusConnectionResolver
    field :admin_mixin_message_connection, resolver: Resolvers::AdminMixinMessageConnectionResolver
    field :admin_mixin_network_snapshot_connection, resolver: Resolvers::AdminMixinNetworkSnapshotConnectionResolver

    field :admin_article, resolver: Resolvers::AdminArticleResolver
    field :admin_wallet_balance, resolver: Resolvers::AdminWalletBalanceResolver
  end
end
