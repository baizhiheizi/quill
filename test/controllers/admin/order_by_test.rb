# frozen_string_literal: true

require "test_helper"

# Reads the three places an admin index sort/filter is defined — the
# controller allow-list (`allowed_param`), the `case` branches that pick the
# scope, and the `<option>` values the `_query.html.erb` view renders — so
# the tests below can compare them. The admin controllers are discovered from
# the filesystem, so a new index is covered without touching this file.
module AdminOrderByAllowLists
  CONTROLLER_DIR = "app/controllers/admin"
  VIEW_DIR = "app/views/admin"

  class << self
    # Every admin controller file, sorted.
    def controller_files
      Dir[Rails.root.join(CONTROLLER_DIR, "*_controller.rb")].sort
    end

    # The allow-list of every query parameter the controller guards:
    # `{ order_by: { default: "created_at_desc", values: [...] } }`.
    def allow_lists(controller_file)
      File.read(controller_file)
          .scan(/allowed_param\(:(\w+),\s*"([^"]+)",\s*%w\[([^\]]*)\]\)/)
          .to_h { |name, default, values| [ name.to_sym, { default: default, values: values.split(/\s+/) } ] }
    end

    # The string values of the `case @param` branches.
    def case_branches(controller_file, param)
      lines = File.read(controller_file).lines
      start = lines.index { |line| line.match?(/\A\s*case\s+@#{Regexp.escape(param.to_s)}\s*\z/) }
      return [] unless start

      indent = lines[start][/\A\s*/].length
      values = []
      lines[(start + 1)..].each do |line|
        break if line.match?(/\A\s{#{indent}}end\s*\z/)

        value = line[/\A\s+when\s+"([^"]+)"/, 1]
        values << value if value
      end
      values
    end

    # The `<option>` values the view renders for `form.select :param`.
    def view_options(view_file, param)
      source = File.read(view_file)
      marker = "form.select :#{param},"
      index = source.index(marker)
      return [] unless index

      array_body(source, source.index("[", index)).scan(/,\s*'([^']*)'\s*\]/).flatten
    end

    # The controller file that defines a controller class.
    def controller_file(controller_class)
      Rails.root.join(CONTROLLER_DIR, "#{resource_of(controller_class)}_controller.rb")
    end

    # The `_query.html.erb` view of an admin resource.
    def query_view(controller_class)
      Rails.root.join(VIEW_DIR, resource_of(controller_class), "_query.html.erb")
    end

    # The `admin/<resource>` name of a controller class.
    def resource_of(controller_class)
      controller_class.name.demodulize.delete_suffix("Controller").underscore
    end

    private

    # The content between the brackets of the array literal starting at
    # `start`.
    def array_body(source, start)
      depth = 0
      source[start..].each_char.with_index do |char, offset|
        depth += 1 if char == "["
        depth -= 1 if char == "]"
        return source[(start + 1)...(start + offset)] if depth.zero?
      end
      ""
    end
  end
end

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

  # Every `<option>` the index view renders must still be accepted by the
  # controller. `allowed_param` silently falls back to the default sort for
  # an unknown value, so an option the allow-list dropped would keep
  # rendering while quietly sorting by something else — with no test
  # failing. Every value the view offers is therefore driven through the
  # controller and has to survive unchanged.
  def test_view_sort_and_filter_options_are_preserved
    controller_class = self.class.controller_class
    controller_file = AdminOrderByAllowLists.controller_file(controller_class)
    view_file = AdminOrderByAllowLists.query_view(controller_class)

    AdminOrderByAllowLists.allow_lists(controller_file).each_key do |param|
      options = File.exist?(view_file) ? AdminOrderByAllowLists.view_options(view_file, param) : []
      next if options.empty?

      options.each do |value|
        @controller.params = ActionController::Parameters.new(param => value)
        @controller.send(:index)

        assert_equal value, @controller.instance_variable_get(:"@#{param}"),
          "expected #{param}=#{value.inspect} to survive the allow-list of #{controller_class}"
      end
    end
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

# The static counterpart of the dynamic test above: the controller allow-list,
# the `case` branches and the view's `<option>` values have to be the same
# set. Without this, a sort key could be added to one place and not another
# (for example dropped from the allow-list while the view keeps offering it)
# and every other test would still pass.
class Admin::OrderByAllowListTest < ActiveSupport::TestCase
  test "every allow-listed admin sort and filter matches its case branches and its view options" do
    controllers = AdminOrderByAllowLists.controller_files
    assert_not_empty controllers, "expected to find admin controllers to check"

    checked = 0
    controllers.each do |controller_file|
      AdminOrderByAllowLists.allow_lists(controller_file).each_key do |param|
        checked += 1
        allow_list = AdminOrderByAllowLists.allow_lists(controller_file).fetch(param).fetch(:values)
        branches = AdminOrderByAllowLists.case_branches(controller_file, param)

        assert_equal allow_list.sort, branches.sort,
          "expected the `case @#{param}` branches of #{controller_file} to match its allow-list"

        view_file = view_file_for(controller_file)
        next unless File.exist?(view_file)

        options = AdminOrderByAllowLists.view_options(view_file, param)
        next if options.empty?

        assert_equal allow_list.sort, options.sort,
          "expected the #{param} options of #{view_file} to match the allow-list of #{controller_file}"
      end
    end

    assert_operator checked, :>, 0, "expected at least one allow-listed admin parameter"
  end

  private

  # The `_query.html.erb` view of the admin resource a controller file
  # belongs to.
  def view_file_for(controller_file)
    resource = File.basename(controller_file, "_controller.rb")
    Rails.root.join(AdminOrderByAllowLists::VIEW_DIR, resource, "_query.html.erb")
  end
end
