# frozen_string_literal: true

# == Schema Information
#
# Table name: bonuses
#
#  id          :bigint           not null, primary key
#  amount      :decimal(, )
#  description :text
#  state       :string
#  title       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  asset_id    :string
#  trace_id    :uuid
#  user_id     :bigint
#
# Indexes
#
#  index_bonuses_on_trace_id  (trace_id) UNIQUE
#  index_bonuses_on_user_id   (user_id)
#

require "test_helper"

# NOTE: `app/models/bonus.rb` does not override `self.table_name`. Rails 8
# inflects `Bonus` → `bonus` (singular — "bonus" doesn't match the standard
# English plural rules), but the migration created `bonuses` (plural). To
# exercise the model without modifying business code, the suite sets the
# table_name at the start of every example.
class BonusTest < ActiveSupport::TestCase
  setup do
    Bonus.table_name = "bonuses"
    @user = users(:author)
    @currency = currencies(:btc)
  end

  def build_bonus(attrs = {})
    Bonus.new({
      user: @user,
      currency: @currency,
      asset_id: @currency.asset_id,
      title: "Thanks for reading!",
      amount: 0.00001
    }.merge(attrs))
  end

  test "valid bonus with required attributes can be saved" do
    bonus = build_bonus

    assert bonus.valid?, "expected bonus to be valid, got errors: #{bonus.errors.full_messages.inspect}"
    assert bonus.save
    assert_equal "drafted", bonus.state
    assert bonus.trace_id.present?, "expected trace_id to be auto-assigned"
  end

  test "title is required" do
    bonus = build_bonus(title: nil)

    assert_not bonus.valid?
    assert_includes bonus.errors[:title], "can't be blank"
  end

  test "amount must be greater than or equal to the minimum" do
    bonus = build_bonus(amount: 0)

    assert_not bonus.valid?
    assert_includes bonus.errors[:amount], "must be greater than or equal to 0.00000001"
  end

  test "deliver transitions from drafted to delivering and creates a transfer" do
    bonus = build_bonus
    assert bonus.save
    bonus.reload
    original_trace_id = bonus.trace_id

    assert_difference -> { Transfer.count }, 1 do
      bonus.deliver_with_lock!
    end

    bonus.reload
    assert_equal "delivering", bonus.state
    assert bonus.transfer.present?
    assert_equal "bonus", bonus.transfer.transfer_type
    assert_equal @user.mixin_uuid, bonus.transfer.opponent_id
    assert_equal bonus.amount, bonus.transfer.amount
    assert_equal bonus.asset_id, bonus.transfer.asset_id
    assert_equal original_trace_id, bonus.transfer.trace_id
    assert_equal bonus.title, bonus.transfer.memo
  end

  test "deliver is a no-op when already delivering" do
    bonus = build_bonus
    assert bonus.save
    bonus.deliver_with_lock!
    first_transfer_id = bonus.reload.transfer.id
    first_state = bonus.state

    # Re-running deliver on a non-drafted bonus must not change state or
    # create a second transfer (AASM raises InvalidTransition, but the
    # bonus is delivered via with_lock — the rescue lives at the caller).
    bonus.send(:deliver_with_lock!) rescue nil
    bonus.reload

    assert_equal first_transfer_id, bonus.transfer.id
    assert_equal first_state, bonus.state
  end

  test "complete transitions from delivering to completed" do
    bonus = build_bonus
    assert bonus.save
    bonus.deliver_with_lock!

    bonus.complete!
    assert_equal "completed", bonus.reload.state
  end

  test "complete cannot be called from drafted" do
    bonus = build_bonus
    assert bonus.save

    assert_raises(AASM::InvalidTransition) do
      bonus.complete!
    end
  end

  test "deliver_with_observability returns false and reports when guard fails" do
    bonus = build_bonus
    assert bonus.save
    bonus.deliver_with_lock!
    # Clear transfer so ensure_transfer_created attempts to create again.
    # Stub create_transfer! to return nil to simulate guard failure.
    bonus.transfer = nil
    bonus.define_singleton_method(:create_transfer!) { |**| nil }

    captured = []
    original_logger_warn = Rails.logger.method(:warn)
    Rails.logger.define_singleton_method(:warn) { |msg| captured << msg }
    original_report = Rails.error.method(:report)
    Rails.error.define_singleton_method(:report) { |*args, **kw| captured << [ args, kw ] }

    assert_equal false, bonus.deliver_with_observability!
    assert(captured.any? { |c| c.to_s.include?("Bonus##{bonus.id} deliver guard failed") })

    Rails.logger.define_singleton_method(:warn, original_logger_warn)
    Rails.error.define_singleton_method(:report, original_report)
  end

  test "deliver_with_observability calls deliver! when guard passes" do
    bonus = build_bonus
    assert bonus.save
    bonus.define_singleton_method(:ensure_transfer_created) { transfer || true }

    assert bonus.deliver_with_observability!
    assert_equal "delivering", bonus.reload.state
  end

  test "price_tag formats amount and currency symbol" do
    bonus = build_bonus(amount: 0.00012345)

    assert_equal "0.00012345 BTC", bonus.price_tag
  end

  test "deliver guard reuses existing transfer when one is present" do
    bonus = build_bonus
    assert bonus.save
    bonus.deliver_with_lock!
    existing_transfer = bonus.transfer

    bonus.send(:ensure_transfer_created)
    assert_equal existing_transfer.id, bonus.transfer.id
  end

  test "trace_id is generated automatically by before_validation callback" do
    bonus = build_bonus
    assert_nil bonus.trace_id, "expected fresh instance to have nil trace_id"

    bonus.valid?
    assert_match(/\A[0-9a-f]{8}-/, bonus.trace_id)
  end
end
