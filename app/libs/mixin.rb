# frozen_string_literal: true

# Quill's adapter for the Mixin Network. Everything that has to agree with
# Mixin's own conventions — the transfer idempotency key and the payment memo
# protocol (`Mixin::Memo`) — lives here, so there is exactly one place that
# knows them.
module Mixin
  # Derives the idempotency key for a transfer from the ids of the parties
  # involved. Every persisted `trace_id` on a Transfer is one of these, so the
  # derivation may not change shape: re-running distribution must keep finding
  # the same row rather than minting a second one.
  #
  # It is `MixinBot::Utils.unique_uuid` under the hood — the same computation
  # the mixin_bot gem exposes through a second, partially-defaulted interface:
  #
  #   # mixin_bot-2.5.0 lib/mixin_bot/api/conversation.rb:134
  #   def unique_uuid(user_id, opponent_id = nil)
  #     opponent_id ||= config.app_id
  #     MixinBot.utils.unique_uuid user_id, opponent_id
  #   end
  #
  # so for a fully supplied pair the two interfaces are byte-identical, and
  # this method gives the call sites a single name that does not leak which
  # gem entry point they used to reach for.
  #
  # Argument order is preserved deliberately: `MixinBot::Utils.unique_uuid`
  # folds its arguments pairwise left to right, and the `uuids.sort` in
  # `MixinBot::Utils::Crypto#unique_uuid` (crypto.rb:243) discards the sorted
  # copy it builds, so three or more parts are order-sensitive. The reader
  # revenue salt depends on that order staying exactly as the caller passed
  # it.
  def self.trace_key(*parts)
    MixinBot::Utils.unique_uuid(*parts)
  end
end
