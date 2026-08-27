# frozen_string_literal: true

require "test_helper"

class DesignSystemControllerTest < ActionDispatch::IntegrationTest
  setup do
    @routes = Rails.application.routes
    Rails.application.routes = Rails.application.routes
  end

  test "GET /design-system renders the reference page in development" do
    return unless Rails.env.development? || Rails.env.test?
    get "/design-system"
    assert_response :success
    assert_select "article.ds-reference"
    assert_match(/Design System/, @response.body)
  end

  test "GET /design-system redirects in production with not_found" do
    Rails.env.stub(:production?, true) do
      get "/design-system"
      assert_redirected_to root_path
      assert_equal 404, response.status
    end
  end

  test "DesignSystem::Primitives::Registry.all returns at least one primitive" do
    assert DesignSystem::Primitives::Registry.all.is_a?(Array)
    assert DesignSystem::Primitives::Registry.all.any? { |p| p[:name] == :button }
  end
end
