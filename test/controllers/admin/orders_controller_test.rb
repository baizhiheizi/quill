# frozen_string_literal: true

require "test_helper"

class Admin::OrdersControllerTest < ActionController::TestCase
  tests Admin::OrdersController

  setup do
    @admin = administrators(:one)
    @request.session[:current_admin_id] = @admin.id
    # The default order fixtures carry no buyer/item/currency, and both the
    # index and show views dereference `order.currency.icon_url` unguarded.
    # Wipe them and build well-formed orders instead.
    Order.destroy_all
    @article = articles(:published_paid)
    @order = with_quill_bot_stub do
      create_buy_order!(article: @article, buyer: create_unique_user!, created_at: 1.hour.ago)
    end
  end

  test "index renders successfully with default filters" do
    get :index

    assert_response :success
    assert_not_nil @controller.instance_variable_get(:@orders)
  end

  test "index narrows by buyer_id when given" do
    get :index, params: { buyer_id: @order.buyer_id }

    assert_response :success
    orders = @controller.instance_variable_get(:@orders)
    assert_includes orders, @order
  end

  test "index narrows by item_type and item_id when given" do
    get :index, params: { item_type: "Article", item_id: @article.id }

    assert_response :success
    orders = @controller.instance_variable_get(:@orders)
    assert_includes orders, @order
  end

  test "index filters by state" do
    get :index, params: { state: "paid" }

    assert_response :success
    assert_equal "paid", @controller.instance_variable_get(:@state)
    assert_includes @controller.instance_variable_get(:@orders), @order
  end

  test "index falls back to 'all' state" do
    get :index, params: { state: "all" }

    assert_response :success
    assert_equal "all", @controller.instance_variable_get(:@state)
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

  test "index rejects an unknown order_by with the default" do
    get :index, params: { order_by: "bogus" }

    assert_response :success
    assert_equal "created_at_desc", @controller.instance_variable_get(:@order_by)
  end

  test "index applies ransack query string" do
    get :index, params: { query: @order.trace_id }

    assert_response :success
    orders = @controller.instance_variable_get(:@orders)
    assert_includes orders, @order
  end

  test "show loads an order by id" do
    get :show, params: { id: @order.id }

    assert_response :success
    assert_equal @order.id, @controller.instance_variable_get(:@order).id
  end

  private

  def create_unique_user!
    User.create!(
      uid: SecureRandom.hex(8),
      name: "Buyer #{SecureRandom.hex(4)}",
      mixin_uuid: SecureRandom.uuid,
      mixin_id: SecureRandom.random_number(1_000_000_000).to_s
    )
  end
end
