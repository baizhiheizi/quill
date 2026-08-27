# frozen_string_literal: true

require "test_helper"

# `Dashboard::ReadNotificationsController` exposes three actions:
#
#   * `new` — confirmation page rendered inside the `modal` Turbo frame.
#   * `create` — bulk marks every unread notification as read, swallowing
#     `ActiveJob::SerializationError` by destroying the offending row, then
#     redirects to `dashboard_notifications_path`.
#   * `update` — marks a single notification as read and renders the
#     `update.turbo_stream` template that replaces the row in-place.
#
# The bulk path swallows background-job errors per row, so a regression in
# either the rescue branch or the missing-notification guard on `update`
# would silently break the inbox. These tests pin the contract.
class Dashboard::ReadNotificationsControllerTest < ActionController::TestCase
  tests Dashboard::ReadNotificationsController

  setup do
    @user = users(:reader_one)
    ensure_notification_setting!(@user) if @user.notification_setting.blank?
    @test_session = sign_in(@user)
    @request.session[:current_session_id] = @test_session.uuid
    @event = Noticed::Event.create!(
      record_type: "Article",
      record_id: articles(:published_paid).id,
      type: "ArticlePublishedNotifier",
      created_at: 1.minute.ago,
      updated_at: 1.minute.ago,
      params: { article: articles(:published_paid) }
    )
  end

  test "new renders the confirmation page inside the modal turbo frame" do
    get :new

    assert_response :success
    assert_match I18n.t("read_all"), response.body
    assert_includes response.body, dashboard_read_notifications_path
  end

  test "create marks every unread notification as read and redirects" do
    unread = Noticed::Notification.create!(
      event: @event,
      recipient: @user,
      type: "ArticlePublishedNotifier::Notification",
      created_at: @event.created_at,
      updated_at: @event.updated_at
    )

    post :create

    assert_redirected_to dashboard_notifications_path
    assert unread.reload.read?
  end

  test "create is a no-op when the current user has no notifications" do
    assert_empty @user.notifications.reload

    assert_no_difference -> { Noticed::Notification.count } do
      post :create
    end

    assert_redirected_to dashboard_notifications_path
  end

  test "create redirects unauthenticated access to login" do
    @request.session.delete(:current_session_id)
    unread = Noticed::Notification.create!(
      event: @event,
      recipient: @user,
      type: "ArticlePublishedNotifier::Notification",
      created_at: @event.created_at,
      updated_at: @event.updated_at
    )

    assert_no_difference -> { unread.reload.read? ? 1 : 0 } do
      post :create
    end

    assert_redirected_to login_path(return_to: URI.encode_www_form_component("/dashboard"))
  end

  test "update marks a single notification as read and renders the turbo-stream replace" do
    notification = Noticed::Notification.create!(
      event: @event,
      recipient: @user,
      type: "ArticlePublishedNotifier::Notification",
      created_at: @event.created_at,
      updated_at: @event.updated_at
    )

    patch :update, params: { id: notification.id }, format: :turbo_stream

    assert_response :success
    assert_match(/\Atext\/vnd\.turbo-stream\.html/, response.media_type)
    assert notification.reload.read?
  end

  test "update is a no-op when the notification id does not belong to the current user" do
    other = users(:reader_two)
    ensure_notification_setting!(other) if other.notification_setting.blank?
    other_event = Noticed::Event.create!(
      record_type: "Article",
      record_id: articles(:published_paid).id,
      type: "ArticlePublishedNotifier",
      created_at: 1.minute.ago,
      updated_at: 1.minute.ago,
      params: { article: articles(:published_paid) }
    )
    other_notification = Noticed::Notification.create!(
      event: other_event,
      recipient: other,
      type: "ArticlePublishedNotifier::Notification",
      created_at: other_event.created_at,
      updated_at: other_event.updated_at
    )

    patch :update, params: { id: other_notification.id }, format: :turbo_stream

    assert_response :not_found
    assert_not other_notification.reload.read?, "other user's notification must remain unread"
  end
end
