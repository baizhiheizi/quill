# frozen_string_literal: true

# == Schema Information
#
# Table name: taggings
# Database name: primary
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  article_id :bigint
#  tag_id     :bigint
#
# Indexes
#
#  index_taggings_on_tag_id_and_article_id  (tag_id,article_id) UNIQUE
#

class Tagging < ApplicationRecord
  belongs_to :tag, counter_cache: :articles_count, touch: true
  belongs_to :article, counter_cache: :tags_count, touch: true

  before_destroy :destroy_notifications

  after_create_commit :notify_subscribers

  def notify_subscribers
    return unless article.published?

    # Push the (subscribed-to-tag) - (author-blocked) predicate into
    # SQL subqueries so we never materialize either id list in Ruby.
    # Matches the pattern used by `HomeController#active_authors`
    # (PR #1735) and `Article#notify_subscribers`. The Tag-side
    # subquery targets `target_type: "Tag"` (the action_store gem
    # accepts any target_type); the block filter reuses
    # `User#blocked_user_ids_relation`.
    TaggingCreatedNotifier
      .with(record: self, tagging: self)
      .deliver(
        User
          .where(id: Action.where(target_type: "Tag", target_id: tag.id, action_type: "subscribe").select(:user_id))
          .where.not(id: article.author.blocked_user_ids_relation)
      )
  end

  has_many :noticed_events, as: :record, dependent: :destroy, class_name: "Noticed::Event"

  def destroy_notifications
    noticed_events.where(type: "TaggingCreatedNotifier").destroy_all
  end
end
