# frozen_string_literal: true

# == Schema Information
#
# Table name: comments
#
#  id               :bigint           not null, primary key
#  commentable_type :string
#  content          :string
#  deleted_at       :datetime
#  downvotes_count  :integer          default(0)
#  upvotes_count    :integer          default(0)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  author_id        :bigint
#  commentable_id   :bigint
#
# Indexes
#
#  index_comments_on_author_id                            (author_id)
#  index_comments_on_commentable_type_and_commentable_id  (commentable_type,commentable_id)
#
class Comment < ApplicationRecord
  include SoftDeletable

  belongs_to :author, class_name: 'User', inverse_of: :comments
  belongs_to :commentable, polymorphic: true, counter_cache: true

  validates :content, presence: true, length: { maximum: 1000 }
  validate :ensure_author_account_normal

  after_commit :notify_subscribers_async,
               :subscribe_for_author,
               :update_author_statistics_cache,
               on: :create

  def subscribers
    @subscribers = commentable.commenting_subscribe_by_users.where.not(mixin_uuid: author.mixin_uuid)
  end

  def notify_subscribers_async
    CommentCreatedNotification.with(comment: self).deliver(subscribers)
  end

  def subscribe_for_author
    author.create_action :commenting_subscribe, target: commentable
  end

  def update_author_statistics_cache
    author.update(
      comments_count: author.comments.count
    )
  end

  private

  def ensure_author_account_normal
    return unless new_record?

    errors.add(:author, 'account is banned!') if author&.banned?
  end
end
