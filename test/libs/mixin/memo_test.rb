# frozen_string_literal: true

require "test_helper"

class Mixin::MemoTest < ActiveSupport::TestCase
  setup do
    @article_uuid = SecureRandom.uuid
    @collection_uuid = SecureRandom.uuid
    @citer_uuid = SecureRandom.uuid
    @follow_id = SecureRandom.uuid
  end

  # === Building ===

  test "buy! builds an article purchase memo" do
    memo = Mixin::Memo.buy!(article: item(@article_uuid), follow_id: @follow_id)

    assert_equal({ "t" => "BUY", "a" => @article_uuid, "f" => @follow_id }, Mixin::Memo.decode(memo))
  end

  test "buy! builds a collection purchase memo" do
    memo = Mixin::Memo.buy!(collection: item(@collection_uuid), follow_id: @follow_id)

    assert_equal({ "t" => "BUY", "l" => @collection_uuid, "f" => @follow_id }, Mixin::Memo.decode(memo))
  end

  test "reward! builds a reward memo" do
    memo = Mixin::Memo.reward!(article: item(@article_uuid), follow_id: @follow_id)

    assert_equal({ "t" => "REWARD", "a" => @article_uuid, "f" => @follow_id }, Mixin::Memo.decode(memo))
  end

  test "cite! builds a citation memo" do
    memo = Mixin::Memo.cite!(article: item(@article_uuid), citer: item(@citer_uuid))

    assert_equal({ "t" => "CITE", "a" => @article_uuid, "c" => @citer_uuid }, Mixin::Memo.decode(memo))
  end

  test "revenue! builds a platform revenue memo" do
    memo = Mixin::Memo.revenue!(article: item(@article_uuid))

    assert_equal({ "t" => "REVENUE", "a" => @article_uuid }, Mixin::Memo.decode(memo))
  end

  # === Wire encodings ===

  test "pay memos use the urlsafe alphabet without padding" do
    memo = Mixin::Memo.buy!(article: item(@article_uuid), follow_id: @follow_id)

    assert_not_includes memo, "="
    assert_not_includes memo, "+"
    assert_not_includes memo, "/"
  end

  test "revenue memos keep the standard base64 encoding revenue transfers always carried" do
    memo = Mixin::Memo.revenue!(article: item(@article_uuid))

    assert_equal Base64.encode64({ t: "REVENUE", a: @article_uuid }.to_json), memo
  end

  test "citation memos keep the standard base64 encoding reference transfers always carried" do
    memo = Mixin::Memo.cite!(article: item(@article_uuid), citer: item(@citer_uuid))

    assert_equal Base64.encode64({ t: "CITE", a: @article_uuid, c: @citer_uuid }.to_json), memo
  end

  # === Decoding ===

  test "decode reads both wire encodings back" do
    payload = { t: "BUY", a: @article_uuid }.to_json

    assert_equal({ "t" => "BUY", "a" => @article_uuid }, Mixin::Memo.decode(Base64.urlsafe_encode64(payload, padding: false)))
    assert_equal({ "t" => "BUY", "a" => @article_uuid }, Mixin::Memo.decode(Base64.encode64(payload)))
  end

  test "decode handles the 60-character wrapping Base64.encode64 inserts" do
    payload = { t: "BUY", a: @article_uuid, f: "f" * 40, c: "c" * 40 }.to_json
    wire = Base64.encode64(payload)

    assert_operator wire.lines.length, :>, 1, "the payload must be long enough to wrap"
    assert_equal JSON.parse(payload), Mixin::Memo.decode(wire)
  end

  test "decode fails open to an empty memo for foreign payloads" do
    assert_equal({}, Mixin::Memo.decode(nil))
    assert_equal({}, Mixin::Memo.decode(""))
    assert_equal({}, Mixin::Memo.decode("REFUND"))
    assert_equal({}, Mixin::Memo.decode("not-valid-base64-memo"))
    assert_equal({}, Mixin::Memo.decode(Base64.encode64("plain text, not json")))
    assert_equal({}, Mixin::Memo.decode(Base64.encode64([ 1, 2 ].to_json)))
  end

  test "decode still reads a legacy 4swap memo so it can be recognized" do
    wire = Base64.encode64({ "s" => "4swapTrade", "t" => @article_uuid }.to_json)

    assert_equal({ "s" => "4swapTrade", "t" => @article_uuid }, Mixin::Memo.decode(wire))
  end

  # === The gate ===

  test "quill_payment? accepts every memo type pointed at an article or a collection" do
    Mixin::Memo::TYPES.each do |type|
      assert Mixin::Memo.quill_payment?({ "t" => type, "a" => @article_uuid }), type
      assert Mixin::Memo.quill_payment?({ "t" => type, "l" => @collection_uuid }), type
    end
  end

  test "quill_payment? rejects unknown types and memos without an item" do
    assert_not Mixin::Memo.quill_payment?({ "t" => "SWAP", "a" => @article_uuid })
    assert_not Mixin::Memo.quill_payment?({ "t" => "BUY" })
    assert_not Mixin::Memo.quill_payment?({})
  end

  # === The test stub derives keys with this math, not a parallel one ===

  test "quill bot stub derives keys with the real derivation" do
    api = QuillBotStub::FakeApi.new(client_id: QuillBotStub::FAKE_CLIENT_ID)
    seed = SecureRandom.uuid
    opponent = SecureRandom.uuid

    assert_equal Mixin.trace_key(seed, opponent), api.unique_uuid(seed, opponent)
    # A missing opponent folds against the app id, as the gem's API does.
    assert_equal Mixin.trace_key(seed, QuillBotStub::FAKE_CLIENT_ID), api.unique_uuid(seed)
  end

  private

  # Anything answering `uuid` — the builders only ever read the uuid.
  def item(uuid)
    Struct.new(:uuid).new(uuid)
  end
end
