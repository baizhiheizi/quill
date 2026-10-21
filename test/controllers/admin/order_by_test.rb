# frozen_string_literal: true

require "test_helper"

# Every admin index action picks its sort scope with a `case` on the
# `order_by` query parameter, and the admin users index does the same for
# `filter`. An unrecognised value used to leave that scope `nil`, which
# raised on the next line (`NoMethodError` on `nil.ransack`) and turned the
# request into a 500. These tests pin the behaviour for every admin index
# at once, so a new index cannot reintroduce the bug unnoticed.
#
# The action is called directly instead of rendering the view: several
# admin index views need fixtures that this suite does not have (and the
# bonuses view uses URL helpers that do not exist), and the defect under
# test lives in the controller, not in the view.
module AdminOrderByGuard
  extend ActiveSupport::Concern

  included do
    setup do
      # `Admin::BaseController#authenticate_admin!` only checks
      # `current_admin.blank?`, so the session is set directly.
      @request.session[:current_admin_id] = administrators(:one).id
    end
  end

  def assert_unknown_order_by_is_handled(collection)
    @controller.params = ActionController::Parameters.new(order_by: "not_a_sort_key")
    @controller.send(:index)

    assert_not_nil @controller.instance_variable_get(collection),
      "expected #{collection} to be set for an unknown order_by"
  end

  def assert_unknown_order_by_falls_back_to_default(collection, default)
    @controller.params = ActionController::Parameters.new(order_by: "not_a_sort_key")
    @controller.send(:index)

    assert_equal default, @controller.instance_variable_get(:@order_by)
    assert_not_nil @controller.instance_variable_get(collection)
  end
end

class Admin::ArticlesOrderByTest < ActionController::TestCase
  tests Admin::ArticlesController
  include AdminOrderByGuard

  test "an unknown order_by does not break the index" do
    assert_unknown_order_by_is_handled(:@articles)
  end

  test "an unknown order_by falls back to the default sort" do
    assert_unknown_order_by_falls_back_to_default(:@articles, "created_at_desc")
  end
end

class Admin::BonusesOrderByTest < ActionController::TestCase
  tests Admin::BonusesController
  include AdminOrderByGuard

  setup do
    # Workaround for the inflector issue: see test/models/bonus_test.rb.
    Bonus.table_name = "bonuses"
  end

  test "an unknown order_by does not break the index" do
    assert_unknown_order_by_is_handled(:@bonuses)
  end
end

class Admin::CollectionsOrderByTest < ActionController::TestCase
  tests Admin::CollectionsController
  include AdminOrderByGuard

  test "an unknown order_by does not break the index" do
    assert_unknown_order_by_is_handled(:@collections)
  end
end

class Admin::CommentsOrderByTest < ActionController::TestCase
  tests Admin::CommentsController
  include AdminOrderByGuard

  test "an unknown order_by does not break the index" do
    assert_unknown_order_by_is_handled(:@comments)
  end
end

class Admin::MixinNetworkSnapshotsOrderByTest < ActionController::TestCase
  tests Admin::MixinNetworkSnapshotsController
  include AdminOrderByGuard

  test "an unknown order_by does not break the index" do
    assert_unknown_order_by_is_handled(:@mixin_network_snapshots)
  end
end

class Admin::MixinNetworkUsersOrderByTest < ActionController::TestCase
  tests Admin::MixinNetworkUsersController
  include AdminOrderByGuard

  test "an unknown order_by does not break the index" do
    assert_unknown_order_by_is_handled(:@mixin_network_users)
  end
end

class Admin::OrdersOrderByTest < ActionController::TestCase
  tests Admin::OrdersController
  include AdminOrderByGuard

  test "an unknown order_by does not break the index" do
    assert_unknown_order_by_is_handled(:@orders)
  end
end

class Admin::PaymentsOrderByTest < ActionController::TestCase
  tests Admin::PaymentsController
  include AdminOrderByGuard

  test "an unknown order_by does not break the index" do
    assert_unknown_order_by_is_handled(:@payments)
  end
end

class Admin::PreOrdersOrderByTest < ActionController::TestCase
  tests Admin::PreOrdersController
  include AdminOrderByGuard

  test "an unknown order_by does not break the index" do
    assert_unknown_order_by_is_handled(:@pre_orders)
  end
end

class Admin::StatisticsOrderByTest < ActionController::TestCase
  tests Admin::StatisticsController
  include AdminOrderByGuard

  test "an unknown order_by does not break the index" do
    assert_unknown_order_by_is_handled(:@statistics)
  end
end

class Admin::TransfersOrderByTest < ActionController::TestCase
  tests Admin::TransfersController
  include AdminOrderByGuard

  test "an unknown order_by does not break the index" do
    assert_unknown_order_by_is_handled(:@transfers)
  end
end

class Admin::UsersOrderByTest < ActionController::TestCase
  tests Admin::UsersController
  include AdminOrderByGuard

  test "an unknown order_by does not break the index" do
    assert_unknown_order_by_is_handled(:@users)
  end

  test "an unknown filter does not break the index" do
    @controller.params = ActionController::Parameters.new(filter: "not_a_filter")
    @controller.send(:index)

    assert_not_nil @controller.instance_variable_get(:@users),
      "expected @users to be set for an unknown filter"
  end

  test "an unknown filter falls back to the default filter" do
    @controller.params = ActionController::Parameters.new(filter: "not_a_filter")
    @controller.send(:index)

    assert_equal "all", @controller.instance_variable_get(:@filter)
  end
end
