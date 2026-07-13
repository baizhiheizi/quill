# frozen_string_literal: true

require "test_helper"

class Admin::TransfersControllerTest < ActionController::TestCase
  tests Admin::TransfersController

  setup do
    @admin = administrators(:one)
    @request.session[:current_admin_id] = @admin.id
    @btc = currencies(:btc)
    @author = users(:author)
    @reader = users(:reader_one)
  end

  def create_transfer!(attrs = {})
    Transfer.create!({
      amount: 0.0001,
      asset_id: @btc.asset_id,
      transfer_type: :author_revenue,
      opponent_id: @author.mixin_uuid
    }.merge(attrs))
  end

  test "POST stale marks an unprocessed transfer as stale" do
    transfer = create_transfer!(trace_id: SecureRandom.uuid)

    assert_difference -> { Transfer.stale.count }, 1 do
      post :stale, params: { transfer_id: transfer.id }, format: :turbo_stream
    end

    assert_response :success
    transfer.reload
    assert transfer.stale_at.present?
    assert_equal @admin.id, transfer.staled_by_id
  end

  test "POST stale returns unprocessable entity for processed transfer" do
    transfer = create_transfer!(trace_id: SecureRandom.uuid, processed_at: Time.current)

    post :stale, params: { transfer_id: transfer.id }, format: :turbo_stream

    assert_response :unprocessable_entity
    transfer.reload
    assert_nil transfer.stale_at
  end

  test "POST stale clears retry_at" do
    transfer = create_transfer!(trace_id: SecureRandom.uuid, retry_at: 1.day.from_now)

    post :stale, params: { transfer_id: transfer.id }, format: :turbo_stream

    assert_response :success
    transfer.reload
    assert_nil transfer.retry_at
  end

  test "POST stale redirects to login when unauthenticated" do
    @request.session[:current_admin_id] = nil
    transfer = create_transfer!(trace_id: SecureRandom.uuid)

    post :stale, params: { transfer_id: transfer.id }, format: :turbo_stream

    assert_redirected_to admin_login_path
  end

  test "POST reactivate returns stale transfer to unprocessed" do
    transfer = create_transfer!(trace_id: SecureRandom.uuid)
    transfer.update!(stale_at: Time.current, staled_by_id: @admin.id)

    post :reactivate, params: { transfer_id: transfer.id }, format: :turbo_stream

    assert_response :success
    transfer.reload
    assert_nil transfer.stale_at
    assert_nil transfer.staled_by_id
  end

  test "POST reactivate returns unprocessable entity for processed transfer" do
    transfer = create_transfer!(trace_id: SecureRandom.uuid, processed_at: Time.current)
    transfer.update_column(:stale_at, Time.current)

    post :reactivate, params: { transfer_id: transfer.id }, format: :turbo_stream

    assert_response :unprocessable_entity
    transfer.reload
    assert transfer.stale_at.present?
  end

  test "POST reactivate returns unprocessable entity for non-stale transfer" do
    transfer = create_transfer!(trace_id: SecureRandom.uuid)

    post :reactivate, params: { transfer_id: transfer.id }, format: :turbo_stream

    assert_response :unprocessable_entity
    transfer.reload
    assert_nil transfer.stale_at
  end

  test "GET index with state=stale uses Transfer.stale scope" do
    admin = administrators(:one)
    stale_transfer = create_transfer!(trace_id: SecureRandom.uuid)
    stale_transfer.update!(stale_at: Time.current, staled_by_id: admin.id)

    # Avoid template rendering by intercepting the render call
    @controller.define_singleton_method(:render) { |*| nil }
    get :index, params: { state: "stale" }, format: :turbo_stream
    @controller.singleton_class.remove_method(:render)

    transfers = @controller.instance_variable_get(:@transfers)
    assert_not_nil transfers
    assert_includes transfers, stale_transfer
  end

  test "GET index with state=unprocessed excludes stale transfers" do
    admin = administrators(:one)
    stale_transfer = create_transfer!(trace_id: SecureRandom.uuid)
    stale_transfer.update!(stale_at: Time.current, staled_by_id: admin.id)
    active_transfer = create_transfer!(trace_id: SecureRandom.uuid)

    @controller.define_singleton_method(:render) { |*| nil }
    get :index, params: { state: "unprocessed" }, format: :turbo_stream
    @controller.singleton_class.remove_method(:render)

    transfers = @controller.instance_variable_get(:@transfers)
    assert_not_nil transfers
    assert_includes transfers, active_transfer
    assert_not_includes transfers, stale_transfer
  end
end
