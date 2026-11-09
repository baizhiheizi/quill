# frozen_string_literal: true

require "test_helper"

class Admin::OverviewControllerTest < ActionController::TestCase
  tests Admin::OverviewController

  test "GET index redirects to login when unauthenticated" do
    get :index

    assert_redirected_to admin_login_path
    assert_nil @request.session[:current_admin_id]
  end

  test "GET index renders successfully for a signed-in admin" do
    @request.session[:current_admin_id] = administrators(:one).id

    # The overview embeds the platform wallet's safe outputs, resolved from
    # QuillBot.api.client_id — stubbed here the same way every Mixin-touching
    # controller test does.
    with_quill_bot_stub do
      get :index
    end

    assert_response :success
  end
end
