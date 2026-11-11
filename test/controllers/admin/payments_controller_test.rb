# frozen_string_literal: true

require "test_helper"

class Admin::PaymentsControllerTest < ActionController::TestCase
  tests Admin::PaymentsController

  setup do
    @admin = administrators(:one)
    @request.session[:current_admin_id] = @admin.id
    # The default payment fixtures carry no payer/currency/memo, and the
    # `_payment.html.erb` partial dereferences `payment.currency.icon_url`
    # unguarded. Wipe them and build well-formed payments instead.
    Order.destroy_all
    Payment.destroy_all
    @payment = create_payment!(payer: users(:reader_one), article: articles(:published_paid))
  end

  test "index renders successfully with default filters" do
    get :index

    assert_response :success
    assert_not_nil @controller.instance_variable_get(:@payments)
  end

  test "index narrows by payer_id when given" do
    get :index, params: { payer_id: @payment.payer_id }

    assert_response :success
    payments = @controller.instance_variable_get(:@payments)
    assert_includes payments, @payment
  end

  test "index filters by state" do
    get :index, params: { state: "completed" }

    assert_response :success
    assert_equal "completed", @controller.instance_variable_get(:@state)
    assert_includes @controller.instance_variable_get(:@payments), @payment
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
    get :index, params: { query: @payment.trace_id }

    assert_response :success
    payments = @controller.instance_variable_get(:@payments)
    assert_includes payments, @payment
  end

  test "show loads a payment by id" do
    get :show, params: { id: @payment.id }

    assert_response :success
    assert_equal @payment.id, @controller.instance_variable_get(:@payment).id
  end
end
