# frozen_string_literal: true

require "test_helper"

class Collections::NotifySubscribersJobTest < JobTestCase
  test "perform no-ops for missing collection" do
    assert_nothing_raised { Collections::NotifySubscribersJob.perform_now(-1) }
  end

  test "perform calls notify_subscribers on collection" do
    collection = collections(:one)
    called = false
    collection.define_singleton_method(:notify_subscribers) { called = true }

    stub_class_method(Collection, :find_by, ->(**kwargs) { kwargs[:id] == collection.id ? collection : nil }) do
      Collections::NotifySubscribersJob.perform_now(collection.id)
    end

    assert called
  end
end
