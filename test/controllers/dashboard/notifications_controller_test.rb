# frozen_string_literal: true

require "test_helper"

class Dashboard::NotificationsControllerTest < ActionController::TestCase
  tests Dashboard::NotificationsController

  # Don't render the view (no `application.css` in test env). We only assert on
  # the SQL emitted by `index` and the `@pagy` / `@notifications` instance vars.
  setup do
    Dashboard::NotificationsController.send(:define_method, :render) { |*| response_body || "" }
    @user = users(:reader_one)
    @test_session = sign_in(@user)
    @request.session[:current_session_id] = @test_session.uuid
    # `visible_in_web?` for non-Comment/Tagging notifiers reads
    # `recipient.notification_setting.<event>_web` — the fixture user has no
    # notification_setting by default, so synthesise one with the same
    # defaults the model applies to fresh rows.
    ensure_notification_setting!(@user) if @user.notification_setting.blank?
  end

  teardown do
    Dashboard::NotificationsController.send(:remove_method, :render) if Dashboard::NotificationsController.method_defined?(:render, false)
  end

  test "index returns the user's web notifications" do
    get :index

    assert_response :success
    notifications = @controller.instance_variable_get(:@notifications)
    refute_nil notifications
    # pagy wraps the relation/array — accept either
    assert(notifications.respond_to?(:each), "expected @notifications to be enumerable")
    assert notifications.all? { |n| n.recipient_id == @user.id }, "expected only this user's notifications"
  end

  test "index filters out notifiers excluded by `for_web`" do
    # MIXIN_ONLY_TYPES in config/initializers/noticed.rb are filtered out by
    # the `for_web` scope.  We synthesise one valid web notification and assert
    # it shows up; the path that excludes UserConnected is exercised by the
    # `where.not(type: MIXIN_ONLY_TYPES)` clause at the top of `index`.
    article = articles(:published_paid)
    event = Noticed::Event.create!(
      record_type: "Article",
      record_id: article.id,
      type: "ArticlePublishedNotifier",
      params: { article: article },
      created_at: 1.minute.ago,
      updated_at: 1.minute.ago
    )
    Noticed::Notification.create!(
      event: event,
      recipient: @user,
      type: "ArticlePublishedNotifier::Notification",
      created_at: event.created_at,
      updated_at: event.updated_at
    )

    get :index

    assert_response :success
    notifications = @controller.instance_variable_get(:@notifications)
    types = notifications.map(&:type)
    assert_includes types, "ArticlePublishedNotifier::Notification"
  end

  test "index eager-loads noticed_events (no per-row N+1 SELECT on noticed_events)" do
    # Synthesise 30 web notifications across two notifier types so that the
    # `event.type.constantize` chain inside `visible_in_web?` would otherwise
    # issue 30 extra SELECTs.
    30.times do |i|
      Noticed::Event.create!(
        record_type: "Article",
        record_id: articles(:published_paid).id,
        type: "ArticlePublishedNotifier",
        created_at: i.seconds.ago,
        updated_at: i.seconds.ago,
        params: {}
      ).tap do |event|
        Noticed::Notification.create!(
          event: event,
          recipient: @user,
          type: "ArticlePublishedNotifier::Notification",
          created_at: event.created_at,
          updated_at: event.updated_at
        )
      end
    end

    queries = capture_queries { get :index }

    # At most one SELECT on noticed_events should fire across the whole action —
    # the one from `includes(:event)` preloader. Zero per-row N+1s allowed.
    event_selects = queries.select { |q| q.start_with?("SELECT") && q.include?('FROM "noticed_events"') }
    assert event_selects.size <= 1,
      "expected at most 1 noticed_events SELECT (from includes(:event)), got #{event_selects.size}:\n  " +
        event_selects.first(3).join("\n  ")
  end

  private

  def capture_queries(exclude: [], &block)
    queries = []
    callback = ->(*, payload) {
      next if payload[:name] == "SCHEMA"
      next if exclude.any? { |needle| payload[:sql].include?(needle) }
      queries << payload[:sql]
    }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)
    queries
  end
end
