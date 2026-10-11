# frozen_string_literal: true

module QuillBotStub
  FAKE_CLIENT_ID = "d4444444-4444-4444-8444-444444444444"

  FakeApi = Struct.new(:client_id) do
    def initialize(client_id: QuillBotStub::FAKE_CLIENT_ID)
      super(client_id)
    end

    # The real derivation, not a parallel implementation: `MixinBot::API#unique_uuid`
    # folds a missing opponent against the app id
    # (mixin_bot-2.5.0 lib/mixin_bot/api/conversation.rb:134), so the stub does
    # too. Anything asserting on a derived key is now checked against the same
    # math production uses.
    def unique_uuid(part, opponent_id = nil)
      Mixin.trace_key(part, opponent_id || client_id)
    end

    def unique_conversation_id(part, opponent_id = nil)
      unique_uuid(part, opponent_id)
    end

    def ticker(_asset_id, _at = nil)
      { "price_btc" => "0.001", "price_usd" => "50000" }
    end

    def safe_pay_url(**_options)
      "https://example.com/pay"
    end
  end

  def with_quill_bot_stub(client_id: FAKE_CLIENT_ID)
    api = FakeApi.new(client_id: client_id)
    original_api = QuillBot.method(:api)
    QuillBot.define_singleton_method(:api) { api }
    yield
  ensure
    QuillBot.define_singleton_method(:api, original_api)
  end
end
