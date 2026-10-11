# frozen_string_literal: true

require "test_helper"

class TransfersControllerTest < ActionController::TestCase
  tests TransfersController

  setup do
    @author = users(:author)
    @reader = users(:reader_one)
    @btc = currencies(:btc)
    @article = articles(:published_paid)
  end

  test "index scopes to author_revenue and reader_revenue transfer types" do
    author_revenue = Transfer.create!(
      trace_id: SecureRandom.uuid,
      amount: 0.0001,
      asset_id: @btc.asset_id,
      transfer_type: :author_revenue,
      opponent_id: @author.mixin_uuid,
      source: @article
    )
    reader_revenue = Transfer.create!(
      trace_id: SecureRandom.uuid,
      amount: 0.0001,
      asset_id: @btc.asset_id,
      transfer_type: :reader_revenue,
      opponent_id: @reader.mixin_uuid,
      source: @article
    )
    other = Transfer.create!(
      trace_id: SecureRandom.uuid,
      amount: 0.0001,
      asset_id: @btc.asset_id,
      transfer_type: :quill_revenue,
      opponent_id: SecureRandom.uuid,
      source: @article
    )

    get :index

    assert_response :success
    transfers = @controller.instance_variable_get(:@transfers)
    assert_includes transfers, author_revenue
    assert_includes transfers, reader_revenue
    assert_not_includes transfers, other
  end

  test "stats renders successfully" do
    get :stats

    assert_response :success
  end

  test "index eager-loads the polymorphic source item and its author" do
    # `transfer.source` is a polymorphic `Order`; `source.item` resolves to
    # the underlying `Article`, and `source.item.author` is the author.
    # Build a real Order via the BUY payment path so the eager-load chain
    # (`source: { item: :author }`) actually targets an `item` association.
    order = create_payment!(payer: @reader, article: @article, order_type: "BUY").order
    transfer = Transfer.create!(
      trace_id: SecureRandom.uuid,
      amount: 0.0001,
      asset_id: @btc.asset_id,
      transfer_type: :author_revenue,
      opponent_id: @author.mixin_uuid,
      source: order
    )

    get :index

    transfers = @controller.instance_variable_get(:@transfers)
    t = transfers.first
    assert_equal transfer, t
    assert t.association(:source).loaded?,
           "Expected source to be eager-loaded, got lazy load"
    source = t.association(:source).target
    assert source.association(:item).loaded?,
           "Expected source.item to be eager-loaded, got lazy load"
    item = source.association(:item).target
    assert item.association(:author).loaded?,
           "Expected source.item.author to be eager-loaded, got lazy load"
  end
end
