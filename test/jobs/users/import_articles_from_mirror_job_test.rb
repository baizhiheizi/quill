# frozen_string_literal: true

require "test_helper"

class Users::ImportArticlesFromMirrorJobTest < JobTestCase
  test "perform no-ops for missing user" do
    assert_nothing_raised { Users::ImportArticlesFromMirrorJob.perform_now(-1) }
  end

  test "perform calls import_articles_from_mirror on user" do
    user = users(:author)
    called = false
    user.define_singleton_method(:import_articles_from_mirror) { called = true }

    stub_class_method(User, :find_by, ->(**kwargs) { kwargs[:id] == user.id ? user : nil }) do
      Users::ImportArticlesFromMirrorJob.perform_now(user.id)
    end

    assert called
  end
end
