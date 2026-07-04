# frozen_string_literal: true

require "test_helper"

class HomeFramesIntegrationTest < ActionDispatch::IntegrationTest
  test "hot_tags returns turbo frame" do
    get hot_tags_path, headers: { "Turbo-Frame" => "hot_tags" }
    assert_response :success
    assert_select "turbo-frame#hot_tags"
  end

  test "active_authors returns turbo frame" do
    get active_authors_path, headers: { "Turbo-Frame" => "active_authors" }
    assert_response :success
    assert_select "turbo-frame#active_authors"
  end

  test "selected_articles returns turbo frame" do
    get selected_articles_path, headers: { "Turbo-Frame" => "selected_articles" }
    assert_response :success
    assert_select "turbo-frame#selected_articles"
  end
end
