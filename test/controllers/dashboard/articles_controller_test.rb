# frozen_string_literal: true

require "test_helper"

# Controller-level coverage for `Dashboard::ArticlesController`, which powers
# the "Articles" tab in the dashboard Write workspace. The `index` action
# filters the author's articles by tab (drafted/published/hidden/bought) with
# pagination and eager-loading; the `show` action renders the article detail
# view with per-tab sub-navigation.
class Dashboard::ArticlesControllerTest < ActionController::TestCase
  tests Dashboard::ArticlesController

  include CommerceHelpers
  include QuillBotStub

  setup do
    @author = users(:author)
    session[:current_session_id] = Session.create!(
      user: @author,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid
  end

  # -- index (tab-based filtering) --

  test "index defaults to drafted tab and renders drafted articles" do
    get :index

    assert_response :success
    assert_equal "drafted", @controller.instance_variable_get(:@tab)
    articles = @controller.instance_variable_get(:@articles)
    assert articles.any?
    assert articles.all? { |a| a.state == "drafted" }
  end

  test "index renders published tab" do
    get :index, params: { tab: "published" }

    assert_response :success
    articles = @controller.instance_variable_get(:@articles)
    assert articles.any?
    assert articles.all? { |a| a.state == "published" }
  end

  test "index renders bought tab" do
    buyer = users(:reader_two)
    article = articles(:published_paid)
    session[:current_session_id] = Session.create!(
      user: buyer,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid

    with_quill_bot_stub do
      create_buy_order!(article: article, buyer: buyer)
    end

    get :index, params: { tab: "bought" }

    assert_response :success
    articles = @controller.instance_variable_get(:@articles)
    assert_includes articles, article
  end

  test "index renders empty state for user with no articles" do
    # reader_two has no authored articles
    buyer = users(:reader_two)
    session[:current_session_id] = Session.create!(
      user: buyer,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid

    get :index

    assert_response :success
    articles = @controller.instance_variable_get(:@articles)
    assert articles.blank?
  end

  test "index sets up pagination" do
    get :index

    assert_response :success
    pagy = @controller.instance_variable_get(:@pagy)
    assert_not_nil pagy
    assert_equal 1, pagy.page
  end

  test "index sets active_section to :write for content tabs" do
    get :index, params: { tab: "drafted" }

    assert_response :success
    assert_equal :write, @controller.instance_variable_get(:@active_section)
  end

  test "index sets active_section to :read for bought tab" do
    article = articles(:published_paid)
    with_quill_bot_stub do
      create_buy_order!(article: article, buyer: @author)
    end

    get :index, params: { tab: "bought" }

    assert_response :success
    assert_equal :read, @controller.instance_variable_get(:@active_section)
  end

  # -- show --

  test "show renders article details" do
    article = articles(:published_paid)

    get :show, params: { uuid: article.uuid }

    assert_response :success
    assert_equal article, @controller.instance_variable_get(:@article)
    assert_equal "buy_records", @controller.instance_variable_get(:@tab)
  end

  test "show renders with specified tab" do
    article = articles(:published_paid)

    get :show, params: { uuid: article.uuid, tab: "reward_records" }

    assert_response :success
    assert_equal "reward_records", @controller.instance_variable_get(:@tab)
  end
end
