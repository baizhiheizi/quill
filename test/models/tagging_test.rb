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

require "test_helper"

class TaggingTest < ActiveSupport::TestCase
  # `User#create_action(:subscribe, target: tag)` writes
  # `target_type: "Tag", action_id: <id>` — that pattern mirrors the
  # `target_type: "Tag"` filter in `Tagging#notify_subscribers`.
  def subscribe!(user, tag)
    user.create_action(:subscribe, target: tag) unless user.subscribe_tag?(tag)
  end

  def fresh_article(state: "published", author: users(:author))
    # Build drafted first, then transition via AASM. Setting `state: "published"`
    # + `published_at` in the constructor trips
    # `cannot_edit_frozen_attributes_once_published` because both fields are
    # dirty on the first save.
    article = Article.new(
      uuid: SecureRandom.uuid,
      title: "tagging callbacks",
      intro: "intro",
      author: author,
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      locale: "en",
      free_content_ratio: 0.1,
      readers_revenue_ratio: 0.4,
      platform_revenue_ratio: 0.1,
      author_revenue_ratio: 0.5,
      references_revenue_ratio: 0.0
    )
    article.content = "<p>test</p>"
    article.save!
    article.publish! if state == "published"
    article
  end

  def fresh_tag(name: "tag-#{SecureRandom.hex(2)}")
    Tag.create!(name: name, locale: "en")
  end

  # Notification rows persisted by Noticed for `tagging`. `noticed_notifications`
  # does not denormalise `record` so we have to join through `noticed_events`.
  def notifications_for(tagging, recipient: nil)
    scope = Noticed::Notification
      .joins(:event)
      .where(noticed_events: { record_type: "Tagging", record_id: tagging.id })
    scope = scope.where(recipient: recipient) if recipient
    scope
  end

  # === Associations & Counter Cache ===

  test "belongs_to :tag counter_cache increments articles_count" do
    tag = fresh_tag
    initial = tag.articles_count
    tagging = Tagging.create!(tag: tag, article: fresh_article)

    assert_equal initial + 1, tag.reload.articles_count
    assert tagging.persisted?
  end

  test "belongs_to :article counter_cache increments tags_count" do
    article = fresh_article
    initial = article.tags_count
    tagging = Tagging.create!(tag: fresh_tag, article: article)

    assert_equal initial + 1, article.reload.tags_count
    assert tagging.persisted?
  end

  test "counter_caches decrement on destroy" do
    tag = fresh_tag
    article = fresh_article
    tagging = Tagging.create!(tag: tag, article: article)

    assert_equal 1, tag.reload.articles_count
    assert_equal 1, article.reload.tags_count

    tagging.destroy!

    assert_equal 0, tag.reload.articles_count
    assert_equal 0, article.reload.tags_count
  end

  test "touch: true bumps tag and article updated_at on create" do
    tag = fresh_tag
    article = fresh_article
    original_tag_updated_at = tag.updated_at
    original_article_updated_at = article.updated_at
    travel 1.second do
      Tagging.create!(tag: tag, article: article)
    end

    assert_operator tag.reload.updated_at, :>, original_tag_updated_at
    assert_operator article.reload.updated_at, :>, original_article_updated_at
  end

  test "composite unique index tag_id+article_id prevents duplicates" do
    tag = fresh_tag
    article = fresh_article
    Tagging.create!(tag: tag, article: article)

    assert_raises ActiveRecord::RecordNotUnique do
      Tagging.create!(tag: tag, article: article)
    end
  end

  # === notify_subscribers SQL shape ===

  # Mirrors `OrderTest#notify_subscribers` SQL assertions. Tagging's
  # `notify_subscribers` pushes the (subscribed-to-tag) - (author-blocked)
  # predicate into a subquery so the recipient list never materialises
  # in Ruby (see comment block in `app/models/tagging.rb`).
  test "notify_subscribers pushes subscriber filter to SQL subquery" do
    with_quill_bot_stub do
      tag = tags(:web3)
      author = users(:author)
      article = fresh_article(author: author)
      ensure_notification_setting!(users(:reader_one))
      ensure_notification_setting!(users(:blocked_reader))

      # reader_one subscribes to the tag so the subquery has rows.
      subscribe!(users(:reader_one), tag)
      # blocked_reader subscribes too — they should be excluded by the
      # `where.not(author.blocked_user_ids_relation)` predicate.
      subscribe!(users(:blocked_reader), tag)
      # Author blocks blocked_reader so we exercise the `where.not` arm.
      author.create_action(:block, target: users(:blocked_reader)) unless author.block_user?(users(:blocked_reader))

      tagging = Tagging.create!(tag: tag, article: article)

      queries = capture_queries { tagging.send(:notify_subscribers) }

      # Only one users SELECT — the IN-subquery form, not a materialised id list.
      users_selects = queries.grep(/FROM "users"/)
      assert_equal 1, users_selects.length,
                   "expected 1 FROM users SELECT, got #{users_selects.length}: #{users_selects.inspect}"

      main_select = users_selects.first
      assert_includes main_select,
                      'IN (SELECT "actions"."user_id" FROM "actions"',
                      "subscriber filter should be an IN-subquery, got: #{main_select}"

      # The sub-query must scope by target_type + action_type (Rails binds the
      # literals as positional params: `$1`/`$2`/`$3`).
      assert_includes main_select, '"actions"."target_type" = $1', "subquery should reference target_type"
      assert_includes main_select, '"actions"."target_id" = $2', "subquery should reference target_id"
      assert_includes main_select, '"actions"."action_type" = $3', "subquery should reference action_type"

      # block-side subquery is also pushed into SQL
      assert_includes main_select, "NOT IN (SELECT \"actions\".\"target_id\"",
                      "block filter should be a NOT IN subquery, got: #{main_select}"
    end
  end

  test "notify_subscribers delivers to subscribed readers" do
    with_quill_bot_stub do
      tag = tags(:web3)
      article = fresh_article
      ensure_notification_setting!(users(:reader_one))

      subscribe!(users(:reader_one), tag)

      tagging = Tagging.create!(tag: tag, article: article)
      tagging.send(:notify_subscribers)

      # Database-persisted notification for reader_one (web delivery is on
      # by default per `NotificationSetting::DEFAULT_SETTING`).
      assert_operator notifications_for(tagging, recipient: users(:reader_one)).count, :>=, 1,
                      "expected at least one Noticed::Notification for reader_one"
    end
  end

  test "notify_subscribers is a no-op when the article is not published" do
    tag = tags(:web3)
    article = fresh_article(state: "drafted")
    ensure_notification_setting!(users(:reader_one))
    subscribe!(users(:reader_one), tag)

    tagging = Tagging.create!(tag: tag, article: article)

    assert_nil tagging.send(:notify_subscribers)

    assert_equal 0, notifications_for(tagging, recipient: users(:reader_one)).count
  end

  test "notify_subscribers excludes subscribers whom the author has blocked" do
    # The `where.not(author.blocked_user_ids_relation)` filter removes users
    # that the AUTHOR has blocked from the recipient list — not the reverse.
    # See `User#blocked_user_ids_relation` and the comment block in
    # `app/models/tagging.rb`.
    with_quill_bot_stub do
      tag = tags(:web3)
      author = users(:author)
      article = fresh_article(author: author)
      ensure_notification_setting!(users(:reader_one))
      ensure_notification_setting!(users(:blocked_reader))

      subscribe!(users(:reader_one), tag)
      subscribe!(users(:blocked_reader), tag)
      # Author blocks blocked_reader — must be excluded from recipients.
      author.create_action(:block, target: users(:blocked_reader)) unless author.block_user?(users(:blocked_reader))

      tagging = Tagging.create!(tag: tag, article: article)
      tagging.send(:notify_subscribers)

      assert_operator notifications_for(tagging, recipient: users(:reader_one)).count, :>=, 1,
                      "reader_one should still receive a notification"
      assert_equal 0, notifications_for(tagging, recipient: users(:blocked_reader)).count,
                   "blocked_reader was blocked by the author and should be excluded"
    end
  end

  test "notify_subscribers scopes by tag id and ignores subscribers of other tags" do
    tag = fresh_tag(name: "defi")
    other_tag = fresh_tag(name: "gaming")
    article = fresh_article
    ensure_notification_setting!(users(:reader_one))

    # Subscribe to *other_tag* only — the notify_subscribers filter is
    # `target_id: tag.id`, so this subscriber should be excluded.
    subscribe!(users(:reader_one), other_tag)

    tagging = Tagging.create!(tag: tag, article: article)
    tagging.send(:notify_subscribers)

    assert_equal 0, notifications_for(tagging, recipient: users(:reader_one)).count
  end

  test "notify_subscribers ignores user-targeted subscriptions" do
    # Action.where(target_type: "User", action_type: "subscribe") targets
    # user-follow relationships. `Tagging#notify_subscribers` filters to
    # `target_type: "Tag"`, so a user-follower must not receive a tagging
    # notification even if they "subscribe" to the author.
    tag = tags(:web3)
    article = fresh_article
    ensure_notification_setting!(users(:reader_two))

    subscribe!(users(:reader_two), users(:author))

    tagging = Tagging.create!(tag: tag, article: article)
    tagging.send(:notify_subscribers)

    assert_equal 0, notifications_for(tagging, recipient: users(:reader_two)).count
  end

  test "after_create_commit fires notify_subscribers" do
    with_quill_bot_stub do
      tag = tags(:web3)
      article = fresh_article
      ensure_notification_setting!(users(:reader_one))
      subscribe!(users(:reader_one), tag)

      tagging = Tagging.create!(tag: tag, article: article)

      assert_operator notifications_for(tagging, recipient: users(:reader_one)).count, :>=, 1
    end
  end

  test "after_create_commit does not fire notify_subscribers for unpublished articles" do
    tag = tags(:web3)
    article = fresh_article(state: "drafted")
    ensure_notification_setting!(users(:reader_one))
    subscribe!(users(:reader_one), tag)

    tagging = Tagging.create!(tag: tag, article: article)
    initial_count = notifications_for(tagging, recipient: users(:reader_one)).count

    assert_equal 0, initial_count
  end

  # === destroy_notifications ===

  test "before_destroy removes noticed_events belonging to TaggingCreatedNotifier" do
    tag = tags(:web3)
    article = fresh_article
    ensure_notification_setting!(users(:reader_one))
    subscribe!(users(:reader_one), tag)

    tagging = Tagging.create!(tag: tag, article: article)
    perform_enqueued_jobs

    record_events = tagging.noticed_events.where(type: "TaggingCreatedNotifier")
    assert_operator record_events.count, :>, 0

    tagging.destroy!

    # TaggingCreatedNotifier events are destroyed (along with their notifications).
    assert_equal 0, Noticed::Event.where(id: record_events.pluck(:id)).count
  end

  test "before_destroy :destroy_notifications only touches TaggingCreatedNotifier events" do
    # A `noticing_destroy_job`-style scenario: noticed_events can come from
    # other notifiers using `record: self`. Make sure `destroy_notifications`
    # does not delete events it shouldn't.
    tag = tags(:web3)
    article = fresh_article
    ensure_notification_setting!(users(:reader_one))
    subscribe!(users(:reader_one), tag)

    tagging = Tagging.create!(tag: tag, article: article)
    perform_enqueued_jobs

    # `noticed_events.type` is an STI column — using an existing notifier
    # avoids the inheritance failure while still proving the
    # `type: "TaggingCreatedNotifier"` scope filter works.
    survivor = Noticed::Event.create!(
      record_type: "Tagging",
      record_id: tagging.id,
      type: "TransferProcessedNotifier"
    )

    tagging.send(:destroy_notifications)

    remaining = Noticed::Event.where(id: survivor.id)
    assert_equal 1, remaining.count, "non-TaggingCreatedNotifier events must be left alone"
    assert_equal "TransferProcessedNotifier", remaining.first.type
  ensure
    survivor&.destroy!
  end

  # === noticed_events association ===

  test "has_many :noticed_events, as: :record is reachable" do
    tagging = taggings(:published_paid_web3)
    assert_respond_to tagging, :noticed_events
    assert_equal "Tagging", tagging.noticed_events.new.record_type
  end

  private

  def capture_queries(&block)
    queries = []
    subscriber = ->(*, payload) {
      queries << payload[:sql] unless payload[:name] == "SCHEMA"
    }
    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record", &block)
    queries
  end
end
