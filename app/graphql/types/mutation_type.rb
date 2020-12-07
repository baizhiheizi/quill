# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :create_article, mutation: Mutations::CreateArticleMutation
    field :update_article, mutation: Mutations::UpdateArticleMutation
    field :hide_article, mutation: Mutations::HideArticleMutation
    field :publish_article, mutation: Mutations::PublishArticleMutation
    field :create_comment, mutation: Mutations::CreateCommentMutation
    field :toggle_authoring_subscribe_user_action, mutation: Mutations::ToggleAuthoringSubscribeUserActionMutation
    field :toggle_reading_subscribe_user_action, mutation: Mutations::ToggleReadingSubscribeUserActionMutation
    field :toggle_commenting_subscribe_article_action, mutation: Mutations::ToggleCommentingSubscribeArticleActionMutation
    field :upvote_article, mutation: Mutations::UpvoteArticleMutation
    field :downvote_article, mutation: Mutations::DownvoteArticleMutation
    field :upvote_comment, mutation: Mutations::UpvoteCommentMutation
    field :downvote_comment, mutation: Mutations::DownvoteCommentMutation

    # admin
    field :admin_login, mutation: Mutations::AdminLoginMutation
    field :admin_delete_comment, mutation: Mutations::AdminDeleteCommentMutation
    field :admin_recover_comment, mutation: Mutations::AdminRecoverCommentMutation
    field :admin_block_article, mutation: Mutations::AdminBlockArticleMutation
    field :admin_unblock_article, mutation: Mutations::AdminUnblockArticleMutation
    field :admin_create_announcement, mutation: Mutations::AdminCreateAnnouncementMutation
    field :admin_update_announcement, mutation: Mutations::AdminUpdateAnnouncementMutation
    field :admin_delete_announcement, mutation: Mutations::AdminDeleteAnnouncementMutation
    field :admin_preview_announcement, mutation: Mutations::AdminPreviewAnnouncementMutation
    field :admin_deliver_announcement, mutation: Mutations::AdminDeliverAnnouncementMutation
    field :admin_create_bonus, mutation: Mutations::AdminCreateBonusMutation
    field :admin_update_bonus, mutation: Mutations::AdminUpdateBonusMutation
    field :admin_deliver_bonus, mutation: Mutations::AdminDeliverBonusMutation
    field :admin_ban_user, mutation: Mutations::AdminBanUserMutation
    field :admin_unban_user, mutation: Mutations::AdminUnbanUserMutation
  end
end
