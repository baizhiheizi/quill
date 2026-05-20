# frozen_string_literal: true

module QuillBotStub
  FAKE_CLIENT_ID = "d4444444-4444-4444-8444-444444444444"

  FakeApi = Struct.new(:client_id) do
    def initialize(client_id: QuillBotStub::FAKE_CLIENT_ID)
      super(client_id)
    end

    def unique_uuid(*parts)
      Digest::UUID.uuid_v5(Digest::UUID::URL_NAMESPACE, parts.map(&:to_s).join("-"))
    end

    def unique_conversation_id(*parts)
      unique_uuid(*parts)
    end

    def ticker(_asset_id, _at = nil)
      { "price_btc" => "0.001", "price_usd" => "50000" }
    end
  end

  def with_quill_bot_stub(client_id: FAKE_CLIENT_ID)
    api = FakeApi.new(client_id: client_id)
    original_api = QuillBot.api
    QuillBot.define_singleton_method(:api) { api }
    yield
  ensure
    QuillBot.define_singleton_method(:api) { original_api }
  end
end
