# frozen_string_literal: true

module Mixin
  # The Mixin payment memo protocol — the one place that knows what Quill
  # writes into an on-chain memo and how to read it back.
  #
  # A memo is a small JSON object, base64-encoded onto the wire:
  #
  #   { "t": "BUY" | "REWARD" | "CITE" | "REVENUE",
  #     "a": <article uuid>,        # what is bought, rewarded, cited from
  #     "c": <article uuid>,        # the article being cited (CITE only)
  #     "l": <collection uuid>,     # the collection being bought
  #     "f": <pre_order follow_id> } # the payer's own pre-order reference
  #
  # Two encodings are live in persisted rows and both must keep decoding: SAFE
  # pay memos use the urlsafe alphabet without padding because they travel
  # inside a pay URL, revenue memos use standard base64, which `Base64.encode64`
  # wraps at 60 characters. `decode` normalizes either into the same hash.
  #
  # `decode` fails OPEN and returns `{}` for anything that is not a memo we
  # wrote. The chain delivers memos we did not author — plain text from other
  # apps, refund labels, the retired 4swap protocol — and a snapshot or payment
  # carrying one must still be recorded and marked processed rather than
  # breaking ingestion. `quill_payment?` is the gate that decides whether a
  # decoded memo is ours to act on.
  module Memo
    TYPES = %w[BUY REWARD CITE REVENUE].freeze

    module_function

    # A purchase of an article or a collection, placed through a SAFE pay URL.
    def buy!(article: nil, collection: nil, follow_id: nil)
      payload = { t: "BUY" }
      payload[:a] = article.uuid if article
      payload[:l] = collection.uuid if collection
      payload[:f] = follow_id if follow_id

      encode_urlsafe payload
    end

    def reward!(article:, follow_id: nil)
      encode_urlsafe({ t: "REWARD", a: article.uuid, f: follow_id })
    end

    # Revenue routed to the author of a cited article.
    def cite!(article:, citer:)
      encode({ t: "CITE", a: article.uuid, c: citer.uuid })
    end

    # The platform's own share of a payment.
    def revenue!(article:)
      encode({ t: "REVENUE", a: article.uuid })
    end

    # urlsafe alphabet, no padding — the SAFE pay-URL encoding.
    def encode_urlsafe(payload)
      Base64.urlsafe_encode64(payload.to_json, padding: false)
    end

    # standard base64 — the encoding revenue transfers have always carried.
    def encode(payload)
      Base64.encode64(payload.to_json)
    end

    def decode(wire)
      parsed = JSON.parse(Base64.strict_decode64(normalized(wire)))
      parsed.is_a?(Hash) ? parsed : {}
    rescue ArgumentError, JSON::ParserError, EncodingError
      {}
    end

    # Whether a decoded memo is one Quill acted on: a known type pointing at
    # either an article or a collection.
    def quill_payment?(memo)
      memo.key?("t") &&
        memo["t"].in?(TYPES) &&
        (memo.key?("a") || memo.key?("l"))
    end

    def normalized(wire)
      string = wire.to_s.delete("\r\n").tr("-_", "+/")
      string + "=" * ((4 - string.length % 4) % 4)
    end
  end
end
