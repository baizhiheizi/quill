# frozen_string_literal: true

require "test_helper"

class Orders::UpdateCacheJobTest < JobTestCase
  test "perform updates article revenue" do
    article = articles(:published_paid)

    with_quill_bot_stub do
      create_buy_order!(article: article, buyer: users(:reader_one), total: 1.0)
      perform_enqueued_jobs(only: Orders::UpdateCacheJob)
    end

    article.reload
    assert_operator article.revenue_usd.to_f, :>, 0
  end
end
