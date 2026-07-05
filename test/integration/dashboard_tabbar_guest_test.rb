# frozen_string_literal: true

require "test_helper"

# Regression test for a production incident: the mobile bottom
# `shared/_dashboard_tabbar` partial called `current_user.has_unread_notification?`
# unconditionally in `layouts/application.html.erb`, so any anonymous mobile
# request (crawlers, logged-out visitors) raised `NoMethodError` wrapped in an
# `ActionView::Template::Error`. Every raised exception fired an
# `ExceptionNotifier::MixinBotNotifier` message through the shared Mixin bot
# API client, and the resulting flood of notifications triggered
# `MixinBot::RateLimitError`s on that same client — which also handles Mixin
# OAuth token exchange, breaking login for everyone.
class DashboardTabbarGuestIntegrationTest < ActionDispatch::IntegrationTest
  MOBILE_USER_AGENT =
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 " \
    "(KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

  test "guest mobile request to a public page renders without raising" do
    user = users(:author)

    get user_subscribe_by_users_path(user), headers: { "User-Agent" => MOBILE_USER_AGENT }

    assert_response :success
    assert_no_match(/#<NoMethodError/, response.body)
  end

  test "guest mobile request does not render the signed-in-only dashboard tabbar" do
    user = users(:author)

    get user_subscribe_by_users_path(user), headers: { "User-Agent" => MOBILE_USER_AGENT }

    assert_response :success
    assert_select "nav.fixed.bottom-0", count: 0
  end
end
