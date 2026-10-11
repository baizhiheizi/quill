# frozen_string_literal: true

require "test_helper"

class MixinTest < ActiveSupport::TestCase
  setup do
    @a = "0a0a0a0a-0a0a-0a0a-0a0a-0a0a0a0a0a0a"
    @b = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
    @c = "cccccccc-cccc-cccc-cccc-cccccccccccc"
  end

  test "trace_key is the mixin_bot derivation" do
    assert_equal MixinBot::Utils.unique_uuid(@a, @b), Mixin.trace_key(@a, @b)
  end

  test "trace_key matches the other gem interface for a fully supplied pair" do
    # `QuillBot.api.unique_uuid(user_id, opponent_id)` resolves to
    # `MixinBot.utils.unique_uuid(user_id, opponent_id)` — see
    # mixin_bot-2.5.0 lib/mixin_bot/api/conversation.rb:134. Every call site
    # that moved to `Mixin.trace_key` passed both arguments, so the persisted
    # keys are unchanged.
    assert_equal Mixin.trace_key(@a, @b), MixinBot::Utils.unique_uuid(@a, @b)
    assert_equal Mixin.trace_key(@b, @a), MixinBot::Utils.unique_uuid(@b, @a)
  end

  test "trace_key is order-independent for two parts and order-sensitive beyond" do
    assert_equal Mixin.trace_key(@a, @b), Mixin.trace_key(@b, @a)
    assert_not_equal Mixin.trace_key(@a, @b, @c), Mixin.trace_key(@c, @b, @a),
                     "the pairwise fold is left-to-right, so a salt's order is load-bearing"
  end

  test "trace_key preserves the caller's argument order for a salt" do
    salt = [ @a, @c, @b ]

    assert_equal MixinBot::Utils.unique_uuid(@a, @c, @b), Mixin.trace_key(*salt)
  end
end
