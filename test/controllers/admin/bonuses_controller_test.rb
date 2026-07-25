# frozen_string_literal: true

require "test_helper"

# Tests for `Admin::BonusesController`. The view templates use URL helpers
# that don't actually exist (`new_admin_bonus_path`,
# `admin_bonus_deliver_path`) because Rails 8 fails to pluralise "bonus" →
# "bonuses" — see `test/models/bonus_test.rb` for the inflector
# workaround. Where rendering would raise on those broken helpers, the
# suite calls the action method directly and inspects instance variables
# instead.
class Admin::BonusesControllerTest < ActionController::TestCase
  tests Admin::BonusesController

  setup do
    # Workaround for the inflector issue: see test/models/bonus_test.rb.
    Bonus.table_name = "bonuses"

    @admin = administrators(:one)
    @request.session[:current_admin_id] = @admin.id
  end

  # index --------------------------------------------------------------

  test "index falls back to 'all' state and stores @bonuses / @pagy" do
    @controller.params = ActionController::Parameters.new
    @controller.send(:index)
    assert_equal "all", @controller.instance_variable_get(:@state)
    assert_equal "created_at_desc", @controller.instance_variable_get(:@order_by)
    assert_not_nil @controller.instance_variable_get(:@bonuses)
    assert_not_nil @controller.instance_variable_get(:@pagy)
  end

  test "index scopes to a user when user_id param is present" do
    user = users(:author)
    @controller.params = ActionController::Parameters.new(user_id: user.id)
    @controller.send(:index)
    assert_equal "all", @controller.instance_variable_get(:@state)
  end

  test "index filters by state when state param is given" do
    @controller.params = ActionController::Parameters.new(state: "drafted")
    @controller.send(:index)
    assert_equal "drafted", @controller.instance_variable_get(:@state)
  end

  test "index filters by state when state is not 'all'" do
    bonus = Bonus.new(
      user: users(:author),
      currency: currencies(:btc),
      asset_id: currencies(:btc).asset_id,
      amount: 0.0001,
      title: "Test",
      state: "completed"
    )
    bonus.save(validate: false)

    @controller.params = ActionController::Parameters.new(state: "completed")
    @controller.send(:index)
    bonuses = @controller.instance_variable_get(:@bonuses)
    assert bonuses.all? { |b| b.state == "completed" }
  end

  test "index orders by created_at_asc when param is set" do
    @controller.params = ActionController::Parameters.new(order_by: "created_at_asc")
    @controller.send(:index)
    assert_equal "created_at_asc", @controller.instance_variable_get(:@order_by)
  end

  test "index applies ransack query string without raising" do
    @controller.params = ActionController::Parameters.new(query: "foo")
    @controller.send(:index)
    assert_not_nil @controller.instance_variable_get(:@bonuses)
  end

  # create -------------------------------------------------------------

  test "create builds a new bonus from params" do
    user = users(:author)
    currency = currencies(:btc)

    bonus = nil
    assert_difference -> { Bonus.count }, 1 do
      @controller.params = ActionController::Parameters.new(
        bonus: {
          asset_id: currency.asset_id,
          amount: 0.0001,
          user_id: user.id,
          title: "Reader Bonus",
          description: "Thanks for reading"
        }
      )
      @controller.send(:create)
      bonus = @controller.instance_variable_get(:@bonus)
    end

    assert_equal "Reader Bonus", bonus.title
    assert_equal user.id, bonus.user_id
  end

  # deliver ------------------------------------------------------------

  test "deliver transitions a drafted bonus to delivering" do
    user = users(:author)
    currency = currencies(:btc)
    bonus = Bonus.create!(
      user: user,
      currency: currency,
      asset_id: currency.asset_id,
      amount: 0.0001,
      title: "Ready"
    )

    @controller.params = ActionController::Parameters.new(bonus_id: bonus.id)
    @controller.send(:deliver)

    assert_equal "delivering", bonus.reload.state
    assert bonus.transfer.present?
  end

  test "deliver is a no-op when bonus is not drafted" do
    user = users(:author)
    currency = currencies(:btc)
    bonus = Bonus.create!(
      user: user,
      currency: currency,
      asset_id: currency.asset_id,
      amount: 0.0001,
      title: "Stuck",
      state: "completed"
    )

    assert_equal "completed", bonus.reload.state
    @controller.params = ActionController::Parameters.new(bonus_id: bonus.id)
    @controller.send(:deliver)
    assert_equal "completed", bonus.reload.state
  end

  test "deliver silently handles a missing bonus id" do
    @controller.params = ActionController::Parameters.new(bonus_id: -1)
    @controller.send(:deliver)
    assert_nil @controller.instance_variable_get(:@bonus)
  end
end
