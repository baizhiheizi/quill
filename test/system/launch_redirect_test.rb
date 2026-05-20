# frozen_string_literal: true

require "application_system_test_case"

class LaunchRedirectTest < ApplicationSystemTestCase
  test "root is accessible when launch gate is open" do
    visit root_path

    assert_text "Quill"
  end
end
