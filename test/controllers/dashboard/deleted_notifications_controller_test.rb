# frozen_string_literal: true

require "test_helper"

# `Dashboard::DeletedNotificationsController` exposes two paths that mutate the
# current user's notification inbox:
#
#   * `new` — confirmation page rendered inside the `modal` Turbo frame.
#   * `create` — bulk-destroys every notification belonging to the user, then
#     redirects back to `dashboard_notifications_path`.
#
# Both routes are gated by `Dashboard::BaseController#authenticate_user!`, so a
# regression there would let an unauthenticated request wipe notifications.
# These tests pin the auth boundary, the bulk-destroy semantics, and the
# scope boundary that prevents cross-user deletes.
class Dashboard::DeletedNotificationsControllerTest < ActionController::TestCase
  tests Dashboard::DeletedNotificationsController

  setup do
    @user = users(:reader_one)
    ensure_notification_setting!(@user) if @user.notification_setting.blank?
    @test_session = sign_in(@user)
    @request.session[:current_session_id] = @test_session.uuid
  end

  test "new renders the confirmation page inside the modal turbo frame" do
    get :new

    assert_response :success
    assert_match I18n.t("clear_all"), response.body
    assert_includes response.body, dashboard_deleted_notifications_path
  end

  test "create destroys every notification belonging to the current user and redirects" do
    event = Noticed::Event.create!(
      record_type: "Article",
      record_id: articles(:published_paid).id,
      type: "ArticlePublishedNotifier",
      created_at: 1.minute.ago,
      updated_at: 1.minute.ago,
      params: {}
    )
    mine = Noticed::Notification.create!(
      event: event,
      recipient: @user,
      type: "ArticlePublishedNotifier::Notification",
      created_at: event.created_at,
      updated_at: event.updated_at
    )

    other = users(:reader_two)
    ensure_notification_setting!(other) if other.notification_setting.blank?
    other_event = Noticed::Event.create!(
      record_type: "Article",
      record_id: articles(:published_paid).id,
      type: "ArticlePublishedNotifier",
      created_at: 1.minute.ago,
      updated_at: 1.minute.ago,
      params: {}
    )
    other_notification = Noticed::Notification.create!(
      event: other_event,
      recipient: other,
      type: "ArticlePublishedNotifier::Notification",
      created_at: other_event.created_at,
      updated_at: other_event.updated_at
    )

    assert_difference -> { @user.notifications.count }, -1 do
      assert_no_difference -> { other.notifications.count } do
        post :create
      end
    end

    assert_redirected_to dashboard_notifications_path
    assert_not Noticed::Notification.exists?(mine.id), "current user's notification should be destroyed"
    assert Noticed::Notification.exists?(other_notification.id), "other user's notification must remain"
  end

  test "create redirects unauthenticated access to login" do
    @request.session.delete(:current_session_id)
    event = Noticed::Event.create!(
      record_type: "Article",
      record_id: articles(:published_paid).id,
      type: "ArticlePublishedNotifier",
      created_at: 1.minute.ago,
      updated_at: 1.minute.ago,
      params: {}
    )
    Noticed::Notification.create!(
      event: event,
      recipient: @user,
      type: "ArticlePublishedNotifier::Notification",
      created_at: event.created_at,
      updated_at: event.updated_at
    )

    assert_no_difference -> { @user.notifications.count } do
      post :create
    end

    assert_redirected_to login_path(return_to: URI.encode_www_form_component("/dashboard"))
  end
end
