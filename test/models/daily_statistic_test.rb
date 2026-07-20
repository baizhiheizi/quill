# frozen_string_literal: true

# == Schema Information
#
# Table name: statistics
# Database name: primary
#
#  id         :bigint           not null, primary key
#  data       :jsonb
#  datetime   :datetime
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require "test_helper"

class DailyStatisticTest < ActiveSupport::TestCase
  setup do
    DailyStatistic.delete_all
    Transfer.delete_all
    Order.delete_all
    Payment.delete_all
  end

  test "is an STI subclass of Statistic with the right type column" do
    assert DailyStatistic < Statistic
    assert_equal "DailyStatistic", DailyStatistic.new.type
    assert_includes DailyStatistic.new.class.ancestors, Statistic
  end

  test "Statistic.where(type: 'DailyStatistic') finds DailyStatistic rows" do
    stat = DailyStatistic.create!(datetime: 1.day.ago, data: {})

    found = Statistic.where(type: "DailyStatistic")
    assert_includes found, stat
  end

  test "store_accessor exposes all 7 data fields for read and write" do
    stat = DailyStatistic.new(
      datetime: 1.day.ago,
      new_users_count: 1,
      paid_users_count: 2,
      new_payments_count: 3,
      new_payers_count: 4,
      new_articles_count: 5,
      author_revenue_total_in_usd: 6.0,
      reader_revenue_total_in_usd: 7.0
    )
    stat.save!(validate: false)

    assert_equal 1, stat.new_users_count
    assert_equal 2, stat.paid_users_count
    assert_equal 3, stat.new_payments_count
    assert_equal 4, stat.new_payers_count
    assert_equal 5, stat.new_articles_count
    assert_equal 6, stat.author_revenue_total_in_usd
    assert_equal 7, stat.reader_revenue_total_in_usd

    stat.new_payers_count = 99
    assert_equal 99, stat.new_payers_count
    assert_equal({ "new_users_count" => 1, "paid_users_count" => 2, "new_payments_count" => 3,
                    "new_payers_count" => 99, "new_articles_count" => 5,
                    "author_revenue_total_in_usd" => 6.0, "reader_revenue_total_in_usd" => 7.0 },
                 stat.data)
  end

  test "store_accessor fields default to nil when data column is unset" do
    stat = DailyStatistic.new(datetime: 1.day.ago)
    assert_nil stat.new_users_count
    assert_nil stat.paid_users_count
    assert_nil stat.new_payments_count
    assert_nil stat.new_payers_count
    assert_nil stat.new_articles_count
    assert_nil stat.author_revenue_total_in_usd
    assert_nil stat.reader_revenue_total_in_usd
  end

  test "data column preserves arbitrary keys beyond the declared accessors" do
    stat = DailyStatistic.new(datetime: 1.day.ago)
    stat.data = { "new_users_count" => 5, "extra_metric" => "future-proof" }
    stat.save!(validate: false)

    assert_equal "future-proof", stat.reload.data["extra_metric"]
    assert_equal 5, stat.new_users_count
  end

  test "default_scope orders by datetime ascending" do
    oldest = DailyStatistic.new(datetime: 3.days.ago, data: {})
    oldest.save!(validate: false)
    middle = DailyStatistic.new(datetime: 1.day.ago, data: {})
    middle.save!(validate: false)
    newest = DailyStatistic.new(datetime: Time.current, data: {})
    newest.save!(validate: false)

    ordered = DailyStatistic.all.to_a
    assert_equal [ oldest, middle, newest ], ordered
  end

  test "generate finds-or-creates a row by datetime" do
    date = 2.days.ago
    found = DailyStatistic.generate(date: date)
    assert_equal date.to_i, found.datetime.to_i

    same = DailyStatistic.generate(date: date)
    assert_equal found, same
    assert_equal 1, DailyStatistic.where(datetime: date.beginning_of_day..date.end_of_day).count
  end

  test "generate creates a new row when none exists for the date" do
    refute DailyStatistic.where(datetime: 5.days.ago.beginning_of_day..5.days.ago.end_of_day).exists?

    DailyStatistic.generate(date: 5.days.ago)

    assert DailyStatistic.where(datetime: 5.days.ago.beginning_of_day..5.days.ago.end_of_day).exists?
  end

  test "regenerate overwrites data with fresh data_attributes for the same datetime" do
    stat = DailyStatistic.new(datetime: 1.day.ago, data: { "new_users_count" => 999 })
    stat.save!(validate: false)

    seed_users(count: 2, created_at: 1.day.ago)

    stat.regenerate

    assert_equal 2, stat.reload.new_users_count
  end

  test "data_attributes new_users_count counts User rows whose created_at falls within the day" do
    _in_day     = seed_users(count: 2, created_at: 1.day.ago)
    _before_day = seed_users(count: 3, created_at: 5.days.ago)
    _after_day  = seed_users(count: 4, created_at: Time.current)

    stat = DailyStatistic.new(datetime: 1.day.ago).data_attributes(1.day.ago)

    assert_equal 2, stat[:new_users_count]
  end

  test "data_attributes new_payments_count counts completed orders within the day only" do
    seller = users(:author)

    in_day = build_order(state: "completed", order_type: 0, buyer: users(:reader_one),
                         seller:, created_at: 1.day.ago)
    _out_of_day = build_order(state: "completed", order_type: 0, buyer: users(:reader_two),
                              seller:, created_at: 5.days.ago)
    _pending = build_order(state: "paid", order_type: 0, buyer: users(:reader_one),
                           seller:, created_at: 1.day.ago)

    stat = DailyStatistic.new(datetime: 1.day.ago).data_attributes(1.day.ago)

    window = Order.completed.where(created_at: 1.day.ago.beginning_of_day...1.day.ago.end_of_day)
    # The in-day order is in the window; the out-of-day order is not; pending isn't completed.
    assert_includes window, Order.completed.find(in_day.id)
    refute_includes window, Order.completed.find(_out_of_day.id)
    # data_attributes matches the same window query, including the freshly-created in-day order.
    assert_equal window.count, stat[:new_payments_count]
  end

  test "data_attributes new_payers_count returns distinct buyer count of completed orders in the day" do
    seller = users(:author)
    buyer1 = users(:reader_one)
    buyer2 = users(:reader_two)

    build_order(state: "completed", order_type: 0, buyer: buyer1, seller:, created_at: 1.day.ago)
    build_order(state: "completed", order_type: 0, buyer: buyer2, seller:, created_at: 1.day.ago)
    _out_of_day = build_order(state: "completed", order_type: 0, buyer: buyer2, seller:,
                              created_at: 5.days.ago)

    stat = DailyStatistic.new(datetime: 1.day.ago).data_attributes(1.day.ago)

    # Two distinct buyers (buyer1 + buyer2) had completed orders in the day.
    in_day_buyer_ids = Order.completed.where(order_type: %i[buy_article reward_article buy_collection],
                                             created_at: 1.day.ago.beginning_of_day...1.day.ago.end_of_day)
                               .distinct.pluck(:buyer_id)
    assert_equal 2, (in_day_buyer_ids & [ buyer1.id, buyer2.id ]).size
    assert stat[:new_payers_count] >= 2
  end

  test "data_attributes paid_users_count includes buyers with completed orders from any past day (no beginning_of_day bound)" do
    seller = users(:author)
    buyer1 = users(:reader_one)
    buyer2 = users(:reader_two)

    _old_order = build_order(state: "completed", order_type: 0, buyer: buyer1, seller:,
                             created_at: 5.days.ago)
    _in_day = build_order(state: "completed", order_type: 0, buyer: buyer2, seller:,
                          created_at: 1.day.ago)

    stat = DailyStatistic.new(datetime: 1.day.ago).data_attributes(1.day.ago)

    paid_buyer_ids = Order.completed.where(order_type: %i[buy_article reward_article buy_collection],
                                            created_at: ...1.day.ago.end_of_day)
                              .distinct.pluck(:buyer_id)
    assert_includes paid_buyer_ids, buyer1.id, "buyer1 (5 days ago) must be counted"
    assert_includes paid_buyer_ids, buyer2.id, "buyer2 (1 day ago) must be counted"
    assert stat[:paid_users_count] >= 2
  end

  test "data_attributes excludes cite-only orders from all three order-based counts" do
    seller = users(:author)
    buyer = users(:reader_one)

    cite = build_order(state: "completed", order_type: 2, buyer:, seller:,
                       created_at: 1.day.ago)
    refute cite.buy_article?
    refute cite.reward_article?
    refute cite.buy_collection?

    stat = DailyStatistic.new(datetime: 1.day.ago).data_attributes(1.day.ago)
    counted_ids = Order.completed.where(order_type: %i[buy_article reward_article buy_collection],
                                         created_at: 1.day.ago.beginning_of_day...1.day.ago.end_of_day)
                               .pluck(:id)
    refute_includes counted_ids, cite.id
    # No in-day buy_article/reward/buy_collection orders this test — fixtures
    # contribute zero to the same window, so the count must also be zero.
    same_window = Order.completed.where(order_type: %i[buy_article reward_article buy_collection],
                                          created_at: 1.day.ago.beginning_of_day...1.day.ago.end_of_day)
    assert_equal 0, same_window.count
    assert_equal 0, stat[:new_payments_count]
  end

  test "data_attributes new_articles_count includes an article published within the day" do
    in_day = build_article(state: "published", title: "marker-in-#{SecureRandom.hex(4)}",
                           published_at: 1.day.ago.beginning_of_day + 1.hour)

    stat = DailyStatistic.new(datetime: 1.day.ago).data_attributes(1.day.ago)
    window = Article.where(published_at: 1.day.ago.beginning_of_day...1.day.ago.end_of_day)

    assert_includes window.pluck(:id), in_day.id
    assert_equal window.count, stat[:new_articles_count]
  end

  test "data_attributes new_articles_count excludes an article published before the day" do
    _out_of_day = build_article(state: "published", title: "marker-out-#{SecureRandom.hex(4)}",
                                published_at: 5.days.ago)

    stat = DailyStatistic.new(datetime: 1.day.ago).data_attributes(1.day.ago)
    window = Article.where(published_at: 1.day.ago.beginning_of_day...1.day.ago.end_of_day)
    ids = window.pluck(:id)

    refute_includes ids, _out_of_day.id
    assert_equal window.count, stat[:new_articles_count]
  end

  test "data_attributes author_revenue_total_in_usd sums amount * currencies.price_usd for author_revenue transfers in the day" do
    btc = currencies(:btc)

    _a = Transfer.create!(
      transfer_type: :author_revenue, asset_id: btc.asset_id, amount: 0.5,
      trace_id: SecureRandom.uuid, opponent_id: users(:author).mixin_uuid,
      created_at: 1.day.ago.beginning_of_day + 1.hour
    )
    _b = Transfer.create!(
      transfer_type: :author_revenue, asset_id: btc.asset_id, amount: 0.25,
      trace_id: SecureRandom.uuid, opponent_id: users(:author).mixin_uuid,
      created_at: 1.day.ago
    )
    _out_of_day = Transfer.create!(
      transfer_type: :author_revenue, asset_id: btc.asset_id, amount: 99,
      trace_id: SecureRandom.uuid, opponent_id: users(:author).mixin_uuid,
      created_at: 5.days.ago
    )
    _wrong_type = Transfer.create!(
      transfer_type: :reader_revenue, asset_id: btc.asset_id, amount: 99,
      trace_id: SecureRandom.uuid, opponent_id: users(:author).mixin_uuid,
      created_at: 1.day.ago
    )

    stat = DailyStatistic.new(datetime: 1.day.ago).data_attributes(1.day.ago)

    expected = (0.5 + 0.25) * btc.price_usd.to_f
    assert_in_delta expected, stat[:author_revenue_total_in_usd], 0.0001
  end

  test "data_attributes reader_revenue_total_in_usd filters by reader_revenue transfer_type" do
    btc = currencies(:btc)

    Transfer.create!(
      transfer_type: :reader_revenue, asset_id: btc.asset_id, amount: 2.0,
      trace_id: SecureRandom.uuid, opponent_id: users(:reader_one).mixin_uuid,
      created_at: 1.day.ago
    )
    _wrong_type = Transfer.create!(
      transfer_type: :author_revenue, asset_id: btc.asset_id, amount: 2.0,
      trace_id: SecureRandom.uuid, opponent_id: users(:author).mixin_uuid,
      created_at: 1.day.ago
    )

    stat = DailyStatistic.new(datetime: 1.day.ago).data_attributes(1.day.ago)

    expected = 2.0 * btc.price_usd.to_f
    assert_in_delta expected, stat[:reader_revenue_total_in_usd], 0.0001
  end

  test "data_attributes returns a hash with all seven keys" do
    stat = DailyStatistic.new(datetime: 1.day.ago).data_attributes(1.day.ago)

    expected_keys = %i[new_users_count paid_users_count new_payments_count new_payers_count
                      new_articles_count author_revenue_total_in_usd reader_revenue_total_in_usd]
    assert_equal expected_keys.sort, stat.keys.sort
  end

  test "setup_attributes fires on create via before_validation callback" do
    seed_users(count: 1, created_at: 1.day.ago)

    stat = DailyStatistic.create!(datetime: 1.day.ago)

    assert_equal 1, stat.new_users_count
  end

  test "setup_attributes does NOT fire on update" do
    seed_users(count: 1, created_at: 1.day.ago)
    stat = DailyStatistic.create!(datetime: 1.day.ago)
    initial_data = stat.data.dup

    seed_users(count: 5, created_at: 1.day.ago)
    stat.update!(datetime: 12.days.ago)

    # Data column is untouched — callback only fires on :create, not :update.
    assert_equal initial_data, stat.reload.data
  end

  test "explicit data on update wins over setup_attributes rerun" do
    seed_users(count: 1, created_at: 1.day.ago)
    stat = DailyStatistic.create!(datetime: 1.day.ago)

    seed_users(count: 5, created_at: 1.day.ago)
    stat.update!(data: { "new_users_count" => 42 })

    assert_equal 42, stat.reload.new_users_count
  end

  private

  def seed_users(count:, created_at:)
    Array.new(count) do |i|
      User.create!(
        uid: SecureRandom.hex(8),
        name: "Seeded #{created_at.to_i}-#{i}",
        mixin_uuid: SecureRandom.uuid,
        mixin_id: SecureRandom.hex(8),
        locale: "en",
        created_at: created_at,
        updated_at: created_at
      )
    end
  end

  # Build a valid Order that bypasses Order#setup_attributes (which requires a
  # Payment with a non-nil amount) AND bypasses the buyer+item uniqueness
  # validator by giving each order a freshly-created article. We don't care
  # about total/value_btc here — only state/order_type/created_at.
  def build_order(state:, order_type:, buyer:, seller:, created_at:)
    article = build_article(state: "published",
                            title: "order-item-#{SecureRandom.hex(4)}",
                            published_at: 2.days.ago)
    Order.new(
      state: state, order_type: order_type, buyer: buyer, seller: seller, item: article,
      trace_id: SecureRandom.uuid, total: 1, asset_id: article.asset_id,
      created_at: created_at, updated_at: created_at
    ).tap { |o| o.save(validate: false) }
  end

  # Same idea as build_order: bypass Article validations (rich_text_content,
  # intro, frozen-attribute) — we only need published_at / state here.
  def build_article(state:, title:, published_at:)
    Article.new(
      author: users(:author), asset_id: currencies(:btc).asset_id,
      price: 0.001, locale: "en", title: title, uuid: SecureRandom.uuid,
      state: state, published_at: published_at
    ).tap { |a| a.save(validate: false) }
  end
end
