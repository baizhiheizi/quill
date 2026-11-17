# frozen_string_literal: true

require "test_helper"

# Pins CoercesPaginationParams — the before_action that normalises
# out-of-range `?page=` input in both controller hierarchies
# (ApplicationController and Admin::BaseController) before Pagy resolves it.
#
# Without it, `?page=0`, `?page=abc` or any sub-1 value reaches
# Pagy::Countless and raises Pagy::OptionError -> 500 (the #2163 fix), and a
# huge `?page=` passes Pagy but its derived OFFSET (`limit * (page - 1)`)
# overflows a Postgres bigint -> PG::NumericValueOutOfRange -> 500.
#
# In-range values (including the MAX_PAGE boundary) and an absent param must
# pass through untouched, and both sources the app and Pagy read — the
# controller's `params` and `request.GET` — must stay in sync. The probe
# controller renders both; the last test drives the real /articles index
# end-to-end.
class CoercesPaginationParamsTest < IntegrationTestCase
  COERCED_TO_1 = %w[0 -3 abc 10001 99999999999999999999].freeze
  KEPT_AS_IS = %w[2 10000].freeze

  test "coerces out-of-range pages to 1 in both params and request.GET" do
    with_pagination_probe do |path|
      COERCED_TO_1.each do |input|
        get path, params: { page: input }

        assert_response :ok
        assert_equal "1|1", response.body,
          "page=#{input.inspect} should coerce to 1 in both params and request.GET, got #{response.body.inspect}"
      end
    end
  end

  test "an empty page value coerces to 1" do
    with_pagination_probe do |path|
      get path, params: { page: "" }

      assert_response :ok
      assert_equal "1|1", response.body
    end
  end

  test "keeps in-range pages untouched, including the MAX_PAGE boundary" do
    with_pagination_probe do |path|
      KEPT_AS_IS.each do |input|
        get path, params: { page: input }

        assert_response :ok
        assert_equal "#{input}|#{input}", response.body,
          "page=#{input.inspect} should pass through untouched, got #{response.body.inspect}"
      end
    end
  end

  test "leaves an absent page param alone" do
    with_pagination_probe do |path|
      get path

      assert_response :ok
      assert_equal "|", response.body
    end
  end

  test "the real articles index renders for out-of-range pages" do
    get articles_path(page: "0")
    assert_response :success

    get articles_path(page: "99999999999999999999")
    assert_response :success
  end

  private

  def with_pagination_probe
    with_routing do |routes|
      routes.draw { get "pagination_probe" => "pagination_probe#peek" }

      yield "/pagination_probe"
    end
  end
end

class PaginationProbeController < ApplicationController
  def peek
    render plain: "#{params[page_key]}|#{request.GET[page_key]}"
  end
end
