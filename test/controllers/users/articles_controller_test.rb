# frozen_string_literal: true

require "test_helper"

# Controller-level coverage for the public article tab on a user's profile.
# This action is reachable without authentication and branches on the selected
# tab.
class Users::ArticlesControllerTest < ActionController::TestCase
  tests Users::ArticlesController

  setup do
    @author = users(:author)
    @reader = users(:reader_one)
  end

  test "index defaults to the published tab for the selected user" do
    get :index, params: { user_uid: @author.uid }

    assert_response :success
    assert_equal "published", @controller.instance_variable_get(:@tab)
    articles = @controller.instance_variable_get(:@articles).to_a
    assert articles.any?
    assert articles.all? { |article| article.author_id == @author.id }
    assert articles.all?(&:published?)
  end

  test "index returns articles bought by the selected user" do
    article = articles(:published_paid)
    create_buy_order!(article:, buyer: @reader)

    get :index, params: { user_uid: @reader.uid, tab: "bought" }

    assert_response :success
    assert_equal "bought", @controller.instance_variable_get(:@tab)
    assert_includes @controller.instance_variable_get(:@articles), article
  end
end
