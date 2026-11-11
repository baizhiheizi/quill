# frozen_string_literal: true

require "test_helper"

class Admin::StatisticsControllerTest < ActionController::TestCase
  tests Admin::StatisticsController

  setup do
    @admin = administrators(:one)
    @request.session[:current_admin_id] = @admin.id
    # The default statistics fixtures carry neither `type` nor `datetime`,
    # so they load as bare `Statistic` rows and the `_statistic.html.erb`
    # partial (which calls the DailyStatistic accessors and formats
    # `datetime`) crashes. Wipe them and build real DailyStatistics.
    Statistic.destroy_all
    @early = DailyStatistic.create!(datetime: 2.days.ago.beginning_of_day)
    @late = DailyStatistic.create!(datetime: 1.day.ago.beginning_of_day)
  end

  test "index renders successfully with default filters" do
    get :index

    assert_response :success
    assert_not_nil @controller.instance_variable_get(:@statistics)
  end

  test "index filters by STI type when state is given" do
    get :index, params: { state: "DailyStatistic" }

    assert_response :success
    assert_equal "DailyStatistic", @controller.instance_variable_get(:@state)
    statistics = @controller.instance_variable_get(:@statistics)
    assert_equal [ @early, @late ].map(&:id).sort, statistics.map(&:id).sort
  end

  test "index falls back to 'all' state" do
    get :index, params: { state: "all" }

    assert_response :success
    assert_equal "all", @controller.instance_variable_get(:@state)
  end

  test "index orders by datetime_desc by default" do
    get :index

    assert_response :success
    assert_equal "datetime_desc", @controller.instance_variable_get(:@order_by)
  end

  test "index orders by datetime_asc when param is given" do
    get :index, params: { order_by: "datetime_asc" }

    assert_response :success
    assert_equal "datetime_asc", @controller.instance_variable_get(:@order_by)
  end

  test "index rejects an unknown order_by with the default" do
    get :index, params: { order_by: "bogus" }

    assert_response :success
    assert_equal "datetime_desc", @controller.instance_variable_get(:@order_by)
  end
end
