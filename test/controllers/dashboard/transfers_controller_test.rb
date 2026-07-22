# frozen_string_literal: true

require "test_helper"

# Controller-level coverage for `Dashboard::TransfersController`, which renders
# the Finances → Transfers view with role-scoped tabs (author revenue, reader
# revenue, or both). The partial walks `transfer.currency` and
# `transfer.source` (polymorphic Order → Article/Collection) — these must not
# trigger N+1 queries.
class Dashboard::TransfersControllerTest < ActionController::TestCase
  tests Dashboard::TransfersController

  include CommerceHelpers
  include QuillBotStub

  setup do
    @user = users(:author)
    session[:current_session_id] = Session.create!(
      user: @user,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid
    @currency = currencies(:btc)
  end

  test "index with default tab renders all revenue transfers" do
    create_revenue_transfer!(transfer_type: :author_revenue)
    create_revenue_transfer!(transfer_type: :reader_revenue)

    get :index

    assert_response :success
    transfers = @controller.instance_variable_get(:@transfers)
    assert_equal 2, transfers.size
  end

  test "index with author tab filters to author revenue only" do
    create_revenue_transfer!(transfer_type: :author_revenue)
    create_revenue_transfer!(transfer_type: :reader_revenue)

    get :index, params: { tab: "author" }

    assert_response :success
    transfers = @controller.instance_variable_get(:@transfers)
    assert_equal 1, transfers.size
    assert_equal "author_revenue", transfers.first.transfer_type
  end

  test "index with reader tab filters to reader revenue only" do
    create_revenue_transfer!(transfer_type: :author_revenue)
    create_revenue_transfer!(transfer_type: :reader_revenue)

    get :index, params: { tab: "reader" }

    assert_response :success
    transfers = @controller.instance_variable_get(:@transfers)
    assert_equal 1, transfers.size
    assert_equal "reader_revenue", transfers.first.transfer_type
  end

  test "index renders successfully with no transfers" do
    get :index

    assert_response :success
    transfers = @controller.instance_variable_get(:@transfers)
    assert transfers.blank?
  end

  test "index eager-loads the currency association" do
    create_revenue_transfer!(transfer_type: :author_revenue)

    get :index

    transfers = @controller.instance_variable_get(:@transfers)
    t = transfers.first
    assert t.association(:currency).loaded?,
           "Expected currency to be eager-loaded, got lazy load"
  end

  test "stats renders successfully" do
    get :stats

    assert_response :success
  end

  test "stats with role param renders" do
    get :stats, params: { role: "author" }

    assert_response :success
  end

  private

  # Articles used as order items, rotated round-robin so consecutive calls
  # within the same test use distinct articles (the DB has a unique index on
  # `(order_type, buyer_id, item_type, item_id)`).
  ARTICLES_FOR_TRANSFERS = %w[published_paid high_revenue].freeze

  def create_revenue_transfer!(transfer_type:)
    index = @transfer_article_index || 0
    article = articles(ARTICLES_FOR_TRANSFERS[index % ARTICLES_FOR_TRANSFERS.size].to_sym)
    @transfer_article_index = index + 1

    # Create a payment and order to serve as the transfer's polymorphic source.
    # The order needs a real article as its `item` so the transfer partial
    # (which calls `transfer.source.item`) does not raise NilClass errors.
    order = nil
    with_quill_bot_stub do
      order = create_buy_order!(article: article, buyer: @user)
    end

    Transfer.create!(
      opponent_id: @user.mixin_uuid,
      transfer_type: transfer_type,
      trace_id: SecureRandom.uuid,
      asset_id: @currency.asset_id,
      amount: 0.001,
      source: order
    )
  end
end
