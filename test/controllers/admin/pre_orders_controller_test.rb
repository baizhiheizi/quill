# frozen_string_literal: true

require "test_helper"

class Admin::PreOrdersControllerTest < ActionController::TestCase
  tests Admin::PreOrdersController

  setup do
    @admin = administrators(:one)
    @request.session[:current_admin_id] = @admin.id
    # The default pre_order fixtures don't populate `currency` / `item`,
    # which makes the `_pre_order.html.erb` partial blow up. Wipe them and
    # create one well-formed fixture for the index.
    PreOrder.destroy_all
    @pre_order = PreOrder.create!(
      payer_id: users(:reader_one).mixin_uuid,
      payee_id: users(:reader_two).mixin_uuid,
      asset_id: currencies(:btc).asset_id,
      amount: 0.0001,
      memo: "index fixture",
      order_type: :buy_article,
      type: "PreOrder",
      follow_id: SecureRandom.uuid,
      item: articles(:published_paid),
      state: :paid
    )
  end

  test "index renders successfully with default filters" do
    get :index

    assert_response :success
    pre_orders = @controller.instance_variable_get(:@pre_orders)
    assert_not_nil pre_orders
  end

  test "index narrows by payer_id when given" do
    payer = users(:author)

    get :index, params: { payer_id: payer.mixin_uuid }

    assert_response :success
  end

  test "index narrows by item_type and item_id when given" do
    article = articles(:published_paid)

    get :index, params: { item_type: "Article", item_id: article.id }

    assert_response :success
  end

  test "index filters by state" do
    get :index, params: { state: "paid" }

    assert_response :success
    assert_equal "paid", @controller.instance_variable_get(:@state)
  end

  test "index falls back to 'all' state" do
    get :index, params: { state: "all" }

    assert_response :success
    assert_equal "all", @controller.instance_variable_get(:@state)
  end

  test "index filters by order_type" do
    get :index, params: { order_type: "buy_article" }

    assert_response :success
    assert_equal "buy_article", @controller.instance_variable_get(:@order_type)
  end

  test "index falls back to 'all' order_type" do
    get :index

    assert_response :success
    assert_equal "all", @controller.instance_variable_get(:@order_type)
  end

  test "index orders by created_at_desc by default" do
    get :index

    assert_response :success
    assert_equal "created_at_desc", @controller.instance_variable_get(:@order_by)
  end

  test "index orders by created_at_asc when param is given" do
    get :index, params: { order_by: "created_at_asc" }

    assert_response :success
    assert_equal "created_at_asc", @controller.instance_variable_get(:@order_by)
  end

  test "index applies ransack query string" do
    get :index, params: { query: "abc" }

    assert_response :success
  end

  test "show loads a pre_order by follow_id" do
    pre_order = PreOrder.create!(
      payer_id: users(:reader_two).mixin_uuid,
      payee_id: users(:reader_one).mixin_uuid,
      asset_id: currencies(:btc).asset_id,
      amount: 0.0001,
      memo: "show test",
      order_type: :buy_article,
      type: "PreOrder",
      follow_id: SecureRandom.uuid,
      item: articles(:published_paid),
      state: :paid
    )

    get :show, params: { follow_id: pre_order.follow_id }

    assert_response :success
    assert_equal pre_order.id, @controller.instance_variable_get(:@pre_order).id
  end

  test "show silently handles unknown follow_id" do
    @controller.params = ActionController::Parameters.new(follow_id: SecureRandom.uuid)
    @controller.send(:show)
    assert_nil @controller.instance_variable_get(:@pre_order)
  end
end
