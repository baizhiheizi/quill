# frozen_string_literal: true

require "test_helper"

class Orders::NotifyJobTest < JobTestCase
  test "perform no-ops for missing order" do
    assert_nothing_raised { Orders::NotifyJob.perform_now(-1) }
  end

  test "perform calls notify on order" do
    with_quill_bot_stub do
      order = create_buy_order!(article: articles(:published_paid), buyer: users(:reader_one), total: 1.0)
      called = false
      order.define_singleton_method(:notify) { called = true }

      stub_class_method(Order, :find_by, ->(**kwargs) { kwargs[:id] == order.id ? order : nil }) do
        Orders::NotifyJob.perform_now(order.id)
      end

      assert called
    end
  end
end
