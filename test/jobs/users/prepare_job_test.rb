# frozen_string_literal: true

require "test_helper"

class Users::PrepareJobTest < JobTestCase
  test "perform no-ops for missing user" do
    assert_nothing_raised { Users::PrepareJob.perform_now(-1) }
  end

  test "perform calls prepare on user" do
    user = users(:reader_one)
    called = false
    user.define_singleton_method(:prepare) { called = true }

    stub_class_method(User, :find_by, ->(**kwargs) { kwargs[:id] == user.id ? user : nil }) do
      Users::PrepareJob.perform_now(user.id)
    end

    assert called
  end
end
