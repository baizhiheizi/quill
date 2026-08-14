# frozen_string_literal: true

require "test_helper"

# `Dashboard::SubscribeTagsController#index` renders the paginated list of
# tags that `current_user` subscribes to. The list is sourced via the
# `action_store :subscribe, :tag` macro on `User`, which auto-generates
# `subscribe_tags`. Each fixture tag gets a subscribe `Action` row
# pointing at `current_user` as the actor.
class Dashboard::SubscribeTagsControllerTest < ActionController::TestCase
  tests Dashboard::SubscribeTagsController

  setup do
    @reader = users(:reader_one)
    sign_in_as(@reader)
  end

  test "index renders empty state when user subscribes to no tags" do
    get :index

    assert_response :success
    tags = @controller.instance_variable_get(:@tags)
    assert tags.blank?
  end

  test "index renders tags the current_user subscribes to" do
    tag = tags(:web3)
    @reader.create_action(:subscribe, target: tag)

    get :index

    assert_response :success
    tags = @controller.instance_variable_get(:@tags)
    assert_includes tags, tag
  end

  test "index does not include tags the user does not subscribe to" do
    # Don't subscribe to anything; ensure the controller does not fall
    # back to listing every fixture tag.
    get :index

    tags = @controller.instance_variable_get(:@tags)
    refute_includes tags, tags(:tech_zh)
  end

  test "index orders tags by most recently subscribed first" do
    first = tags(:web3)
    second = tags(:tech_zh)
    @reader.create_action(:subscribe, target: first)
    @reader.create_action(:subscribe, target: second)

    get :index

    assert_response :success
    tags = @controller.instance_variable_get(:@tags)
    assert_equal second.id, tags.first.id
  end

  test "index sets up pagination" do
    items_per_page = Pagy::DEFAULT[:items] || 25
    (items_per_page + 1).times do |i|
      tag = Tag.create!(name: "tag-#{i}", locale: :en)
      @reader.create_action(:subscribe, target: tag)
    end

    get :index

    assert_response :success
    pagy = @controller.instance_variable_get(:@pagy)
    assert_not_nil pagy
    assert_equal 2, pagy.pages
  end

  test "index redirects to login for unauthenticated access" do
    @request.session[:current_session_id] = nil

    get :index

    assert_response :redirect
  end

  private

  def sign_in_as(user)
    test_session = sign_in(user)
    @request.session[:current_session_id] = test_session.uuid
  end
end
