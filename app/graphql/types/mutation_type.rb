# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :create_article, mutation: Mutations::CreateArticleMutation
    field :hide_article, mutation: Mutations::HideArticleMutation
    field :publish_article, mutation: Mutations::PublishArticleMutation
    field :create_comment, mutation: Mutations::CreateCommentMutation

    # admin
    field :admin_login, mutation: Mutations::AdminLoginMutation
    field :admin_delete_comment, mutation: Mutations::AdminDeleteCommentMutation
    field :admin_recover_comment, mutation: Mutations::AdminRecoverCommentMutation
    field :admin_block_article, mutation: Mutations::AdminBlockArticleMutation
    field :admin_unblock_article, mutation: Mutations::AdminUnblockArticleMutation
  end
end
