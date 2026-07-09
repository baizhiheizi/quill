# frozen_string_literal: true

require "test_helper"

# `Dashboard::OrdersController#index` renders the per-article orders table
# (`app/views/dashboard/orders/_article_order.html.erb`). The partial walks
# `order.buyer.avatar_image_thumb` (via `shared/_avatar`) and
# `order.citer.author` on the cite_article branch — both associations were
# not eager-loaded before this PR, which meant each row triggered a fan-out
# of SELECTs (authorization + ActiveStorage attachment/blob/variant). The
# regression-guard below asserts the index action completes in a small
# bounded number of SELECTs no matter how many orders the author has.
class Dashboard::OrdersControllerTest < ActionController::TestCase
  tests Dashboard::OrdersController

  SELECT_BUDGET = 30

  setup do
    @author = users(:author)
    sign_in_as(@author)
  end

  test "index renders without triggering per-row SELECT fan-out" do
    article = articles(:published_paid)
    seed_orders!(article: article, count: 50)

    select_count = 0
    counter = ->(_name, _start, _finish, _id, payload) do
      next if payload[:name] == "SCHEMA"

      select_count += 1
    end

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      get :index, params: { article_uuid: article.uuid }
    end

    assert_response :success
    assert_operator select_count, :<=, SELECT_BUDGET,
      "Expected index to fire ≤#{SELECT_BUDGET} SELECTs, got #{select_count}. " \
      "Likely cause: a partial chain (buyer avatar, citer author, item, currency) regressed."
  end

  test "index renders cite_article orders with the cited article author" do
    article = articles(:published_paid)
    cited = articles(:high_revenue)
    seed_cite_orders!(article: article, citer: cited, count: 2)

    get :index, params: { article_uuid: article.uuid, order_type: "cite_article" }

    assert_response :success
    cite_orders = @controller.instance_variable_get(:@orders)
    assert cite_orders.any?
    cite_orders.each { |o| assert_equal cited.author, o.citer.author }
  end

  private

  def sign_in_as(user)
    test_session = sign_in(user)
    @request.session[:current_session_id] = test_session.uuid
  end

  def seed_orders!(article:, count:)
    Array.new(count) do |i|
      buyer = create_unique_user!
      with_quill_bot_stub do
        create_buy_order!(article: article, buyer: buyer, created_at: i.hours.ago)
      end
    end
  end

  def seed_cite_orders!(article:, citer:, count:)
    Array.new(count) do |i|
      buyer = create_unique_user!
      trace_id = SecureRandom.uuid

      stub_notifications! do
        payment = Payment.new(
          amount: article.price,
          raw: {
            "amount" => article.price.to_s,
            "asset_id" => article.asset_id,
            "memo" => build_payment_memo(type: "CITE", article: article, citer: citer),
            "opponent_id" => buyer.mixin_uuid,
            "snapshot_id" => SecureRandom.uuid,
            "trace_id" => trace_id
          },
          asset_id: article.asset_id,
          snapshot_id: SecureRandom.uuid,
          trace_id: trace_id,
          payer: buyer,
          state: "completed"
        )
        payment.define_singleton_method(:generate_order!) { }
        payment.save!(validate: false)
      end

      Order.create!(
        buyer: buyer,
        seller: citer.author,
        item: article,
        payment: Payment.find_by!(trace_id: trace_id),
        citer: citer,
        order_type: :cite_article,
        trace_id: trace_id,
        asset_id: article.asset_id,
        total: article.price,
        value_btc: article.currency.price_btc.to_f * article.price.to_f,
        value_usd: article.currency.price_usd.to_f * article.price.to_f,
        created_at: i.hours.ago,
        updated_at: i.hours.ago
      )
    end
  end

  def create_unique_user!
    User.create!(
      uid: SecureRandom.hex(8),
      name: "Buyer #{SecureRandom.hex(4)}",
      mixin_uuid: SecureRandom.uuid,
      mixin_id: SecureRandom.random_number(1_000_000_000).to_s
    )
  end
end
