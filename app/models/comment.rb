# frozen_string_literal: true

# == Schema Information
#
# Table name: comments
#
#  id               :bigint           not null, primary key
#  commentable_type :string
#  comments_count   :integer          default(0)
#  content          :string
#  deleted_at       :datetime
#  downvotes_count  :integer          default(0)
#  upvotes_count    :integer          default(0)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  author_id        :bigint
#  commentable_id   :bigint
#  quote_comment_id :bigint
#
# Indexes
#
#  index_comments_on_author_id                            (author_id)
#  index_comments_on_commentable_type_and_commentable_id  (commentable_type,commentable_id)
#  index_comments_on_quote_comment_id                     (quote_comment_id)
#

class Comment < ApplicationRecord
  include SoftDeletable

  belongs_to :author, class_name: 'User', inverse_of: :comments
  belongs_to :commentable, polymorphic: true, counter_cache: true
  belongs_to :quote_comment, class_name: 'Comment', inverse_of: :comments, counter_cache: true, optional: true

  has_many :comments, class_name: 'Comment', foreign_key: :quote_comment_id, inverse_of: :quote_comment, dependent: :nullify

  validates :content, presence: true, length: { maximum: 1000 }
  validate :ensure_author_not_blocked, on: :create

  after_commit :notify_subscribers_async,
               :subscribe_for_author,
               on: :create

  def subscribers
    @subscribers ||= commentable.commenting_subscribe_by_users.where.not(mixin_uuid: author.mixin_uuid) if commentable.is_a?(Article)
  end

  def notify_subscribers_async
    CommentCreatedNotification.with(comment: self).deliver(subscribers)
  end

  def subscribe_for_author
    author.create_action :commenting_subscribe, target: commentable if commentable.is_a?(Article)
  end

  def content_as_html
    MarkdownRenderService.call content, type: :full
  end

  private

  def ensure_author_not_blocked
    return unless new_record?

    errors.add(:author, 'blocked') if commentable&.author&.block_user? author
  end
end
