# frozen_string_literal: true

require "test_helper"

class Currencies::SyncJobTest < JobTestCase
  test "perform syncs swappable currencies" do
    currency = currencies(:btc)
    called = false
    currency.define_singleton_method(:sync!) { called = true }

    swappable = Object.new
    swappable.define_singleton_method(:map) { |&block| [ currency ].map(&block) }

    stub_class_method(Currency, :swappable, -> { swappable }) do
      Currencies::SyncJob.perform_now
    end

    assert called
  end
end
