# frozen_string_literal: true

require "test_helper"

class OrderPolicyTest < ActiveSupport::TestCase
  setup do
    @article = articles(:published_paid)
    @buyer = users(:reader_one)
    @author = users(:author)
    @other = users(:reader_two)
  end

  test "show? allows buyer" do
    with_quill_bot_stub do
      order = create_buy_order!(article: @article, buyer: @buyer)

      assert OrderPolicy.new(@buyer, order).show?
    end
  end

  test "show? allows article author" do
    with_quill_bot_stub do
      order = create_buy_order!(article: @article, buyer: @buyer)

      assert OrderPolicy.new(@author, order).show?
    end
  end

  test "show? denies unrelated users" do
    with_quill_bot_stub do
      order = create_buy_order!(article: @article, buyer: @buyer)

      refute OrderPolicy.new(@other, order).show?
    end
  end

  test "show? denies guests" do
    with_quill_bot_stub do
      order = create_buy_order!(article: @article, buyer: @buyer)

      refute OrderPolicy.new(nil, order).show?
    end
  end
end
