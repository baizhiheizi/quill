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
    ensure_notification_setting!(@user)
  end

  teardown do
    Dashboard::NotificationsController.send(:remove_method, :render) if Dashboard::NotificationsController.method_defined?(:render, false)
  end

  test "index returns the user's web notifications" do
    get :index

    assert_response :success
    notifications = @controller.instance_variable_get(:@notifications)
    refute_nil notifications
    # pagy wraps the relation — it must stay a query, not a Ruby array
    assert(notifications.respond_to?(:to_sql), "expected @notifications to be a relation")
    assert notifications.all? { |n| n.recipient_id == @user.id }, "expected only this user's notifications"
  end

  test "index returns only the rows persisted as web visible" do
    web = build_notification!(web_visible: true)
    build_notification!(web_visible: false)

    get :index

    assert_response :success
    notifications = @controller.instance_variable_get(:@notifications)
    assert_equal [ web.type ], notifications.map(&:type)
    assert_equal [ web.id ], notifications.map(&:id)
  end

  test "index is paginated SQL with no per-row N+1 SELECT on noticed_events" do
    30.times { |i| build_notification!(web_visible: true, created_at: i.seconds.ago) }

    queries = capture_queries { get :index }

    # At most one SELECT on noticed_events should fire across the whole action —
    # the one from `includes(:event)` preloader. Zero per-row N+1s allowed.
    event_selects = queries.select { |q| q.start_with?("SELECT") && q.include?('FROM "noticed_events"') }
    assert event_selects.size <= 1,
      "expected at most 1 noticed_events SELECT (from includes(:event)), got #{event_selects.size}:\n  " +
        event_selects.first(3).join("\n  ")
  end

  private

  def build_notification!(web_visible:, created_at: Time.current)
    event = Noticed::Event.create!(
      record_type: "Article",
      record_id: articles(:published_paid).id,
      type: "ArticlePublishedNotifier",
      params: { article: articles(:published_paid) },
      created_at: created_at,
      updated_at: created_at
    )
    Noticed::Notification.create!(
      event: event,
      recipient: @user,
      type: "ArticlePublishedNotifier::Notification",
      web_visible: web_visible,
      created_at: event.created_at,
      updated_at: event.updated_at
    )
  end

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
