# frozen_string_literal: true

require "test_helper"

class NotifiableTest < ActiveSupport::TestCase
  setup do
    @author = users(:author)
    @follower = users(:reader_one)
    @other_follower = users(:reader_two)
    @article = fresh_article(author: @author)
  end

  test "dispatch delivers one event to every recipient in the audience" do
    @follower.create_action :subscribe, target: @author
    @other_follower.create_action :subscribe, target: @author

    with_quill_bot_stub do
      @article.notify!(
        ArticlePublishedNotifier,
        recipient: Notifiers::Audience.subscribed_to(@author),
        article: @article
      )
    end

    event = Noticed::Event.where(record: @article, type: "ArticlePublishedNotifier").last
    assert event, "expected a Noticed::Event anchored to the article"
    assert_equal [ @follower.id, @other_follower.id ].sort,
                 event.notifications.pluck(:recipient_id).sort
  end

  test "the app verb and the test-suite helper funnel into the same dispatch" do
    seen = []
    stub_singleton_method(Notifiable, :dispatch, ->(*args) { seen << args }) do
      @article.notify!(ArticlePublishedNotifier, recipient: @follower, article: @article)
      deliver_notifier!(ArticlePublishedNotifier, record: @article, recipient: @follower, article: @article)
    end

    assert_equal 2, seen.length
    assert_equal [ ArticlePublishedNotifier, { recipient: @follower, record: @article, article: @article } ], seen.first
  end

  test "record defaults to the receiver" do
    seen = []
    stub_singleton_method(Notifiable, :dispatch, ->(*args) { seen << args }) do
      @article.notify!(ArticlePublishedNotifier, recipient: @follower, article: @article)
    end

    assert_equal @article, seen.first.last[:record]
  end

  test "a nil recipient delivers nothing and does not raise" do
    assert_nothing_raised do
      with_quill_bot_stub do
        @article.notify!(ArticlePublishedNotifier, recipient: nil, article: @article)
      end
    end

    assert_equal 0, Noticed::Notification.where(recipient: @follower).count
  end

  test "notify_subscribers reaches every follower through the seam" do
    @follower.create_action :subscribe, target: @author
    @other_follower.create_action :subscribe, target: @author

    with_quill_bot_stub do
      @article.notify_subscribers
    end

    recipients = Noticed::Notification
      .where(recipient: [ @follower, @other_follower ])
      .joins(:event)
      .where(noticed_events: { record: @article, type: "ArticlePublishedNotifier" })

    assert_equal [ @follower.id, @other_follower.id ].sort, recipients.pluck(:recipient_id).sort
  end

  private

  # Same shape as `JobTestCase#stub_class_method`, for module-level methods.
  def stub_singleton_method(klass, method_name, implementation)
    original = klass.method(method_name)
    klass.define_singleton_method(method_name, implementation)
    yield
  ensure
    klass.define_singleton_method(method_name, original)
  end

  def fresh_article(author:)
    article = Article.new(
      uuid: SecureRandom.uuid,
      title: "dispatch verb",
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
    article.content = "<p>dispatch</p>"
    article.save!
    article
  end
end
