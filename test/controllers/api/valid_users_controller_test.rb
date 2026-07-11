# frozen_string_literal: true

require "test_helper"

class API::ValidUsersControllerTest < IntegrationTestCase
  setup do
    @user = users(:reader_one)
    @article = articles(:published_paid)
  end

  # Helper: create a payment tied to `payer` with the given state and
  # `created_at`. The default `Payment.create!(raw:)` flow auto-transitions
  # new payments to "completed" via `place_article_order!` → `complete!`,
  # so to leave the state at "paid" we stub `generate_order!`. To set
  # "completed" or "refunded" we save the default and use `update_columns`
  # to bypass AASM (the controller's filter only reads the column value).
  def create_payment_with_state!(payer:, state:, created_at: Time.current)
    raw = {
      "amount" => @article.price.to_s,
      "asset_id" => @article.asset_id,
      "memo" => Base64.encode64({ "t" => "BUY", "a" => @article.uuid }.to_json),
      "opponent_id" => payer.mixin_uuid,
      "snapshot_id" => SecureRandom.uuid,
      "trace_id" => SecureRandom.uuid
    }
    payment = nil
    stub_notifications! do
      with_quill_bot_stub do
        payment = Payment.new(raw: raw)
        # `Payment.create!` triggers `after_create :generate_order!` which
        # calls `complete!` and would force the state to "completed".
        # Stub it so the state stays at the AASM initial ("paid") before
        # we override via `update_columns` below.
        payment.define_singleton_method(:generate_order!) { }
        payment.save!
      end
    end
    # `update_columns` bypasses AASM and validations, so we can land on
    # any state value the controller's `where(state: %i[paid completed])`
    # query cares about.
    payment.update_columns(state: state, created_at: created_at, updated_at: created_at)
    payment
  end

  test "filter returns false when user_id is unknown" do
    get api_valid_user_filter_path(user_id: SecureRandom.uuid), as: :json

    assert_response :success
    assert_equal({ "approved" => false }, response.parsed_body)
  end

  test "filter returns false when user_id is missing" do
    get api_valid_user_filter_path, as: :json

    assert_response :success
    assert_equal({ "approved" => false }, response.parsed_body)
  end

  test "filter returns false when user has no payments and no published articles (default type)" do
    get api_valid_user_filter_path(user_id: @user.mixin_uuid), as: :json

    assert_response :success
    assert_equal({ "approved" => false }, response.parsed_body)
  end

  test "filter returns true when user has a published article (default type)" do
    # `users(:author)` has multiple published articles in fixtures.
    get api_valid_user_filter_path(user_id: users(:author).mixin_uuid), as: :json

    assert_response :success
    assert_equal({ "approved" => true }, response.parsed_body)
  end

  test "filter returns true when user has a paid payment (default type)" do
    create_payment_with_state!(payer: @user, state: "paid")

    get api_valid_user_filter_path(user_id: @user.mixin_uuid), as: :json

    assert_response :success
    assert_equal({ "approved" => true }, response.parsed_body)
  end

  test "filter returns true when user has a completed payment (default type)" do
    create_payment_with_state!(payer: @user, state: "completed")

    get api_valid_user_filter_path(user_id: @user.mixin_uuid), as: :json

    assert_response :success
    assert_equal({ "approved" => true }, response.parsed_body)
  end

  test "filter ignores payments in a state other than paid or completed (default type)" do
    create_payment_with_state!(payer: @user, state: "refunded")

    get api_valid_user_filter_path(user_id: @user.mixin_uuid), as: :json

    assert_response :success
    assert_equal({ "approved" => false }, response.parsed_body)
  end

  test "filter ignores draft articles (default type)" do
    # `users(:reader_one)` has zero articles in fixtures, so the draft
    # we create will be the user's only article and must not qualify them.
    Article.create!(
      author: @user,
      title: "draft only",
      intro: "draft intro",
      price: 0.0001,
      asset_id: Currency::BTC_ASSET_ID,
      state: "drafted",
      uuid: SecureRandom.uuid,
      locale: "en"
    )
    assert_equal 0, @user.articles.only_published.count

    get api_valid_user_filter_path(user_id: @user.mixin_uuid), as: :json

    assert_response :success
    assert_equal({ "approved" => false }, response.parsed_body)
  end

  test "filter with type=recent returns true when user has a recent paid payment" do
    create_payment_with_state!(payer: @user, state: "paid", created_at: 1.day.ago)

    get api_valid_user_filter_path(user_id: @user.mixin_uuid, type: "recent"), as: :json

    assert_response :success
    assert_equal({ "approved" => true }, response.parsed_body)
  end

  test "filter with type=recent returns false when only payment is older than a week" do
    create_payment_with_state!(payer: @user, state: "paid", created_at: 2.weeks.ago)

    get api_valid_user_filter_path(user_id: @user.mixin_uuid, type: "recent"), as: :json

    assert_response :success
    assert_equal({ "approved" => false }, response.parsed_body)
  end

  test "filter with type=recent returns true when user published an article in the last week" do
    # `high_revenue` fixture is `published_at: 1.day.ago` for users(:author).
    recent_author = users(:author)
    assert_operator recent_author.articles.only_published.where(published_at: 1.week.ago...).count, :>, 0

    get api_valid_user_filter_path(user_id: recent_author.mixin_uuid, type: "recent"), as: :json

    assert_response :success
    assert_equal({ "approved" => true }, response.parsed_body)
  end

  test "filter with type=recent returns false when user's only published article is older than a week" do
    old_article_user = users(:reader_two)
    # Build drafted, then publish via AASM with a content body so the
    # "Content can't be blank" + "Asset cannot change" validations pass.
    article = Article.create!(
      author: old_article_user,
      title: "old article",
      intro: "old intro",
      price: 0.0,
      asset_id: Currency::BTC_ASSET_ID,
      state: "drafted",
      uuid: SecureRandom.uuid,
      locale: "en"
    )
    article.content = "<p>old content</p>"
    article.published_at = 2.weeks.ago
    article.publish!
    assert_operator old_article_user.articles.only_published.count, :>, 0
    assert_operator old_article_user.articles.only_published.where(published_at: 1.week.ago...).count, :==, 0

    get api_valid_user_filter_path(user_id: old_article_user.mixin_uuid, type: "recent"), as: :json

    assert_response :success
    assert_equal({ "approved" => false }, response.parsed_body)
  end

  test "filter with type=recent returns false for an unknown user" do
    get api_valid_user_filter_path(user_id: SecureRandom.uuid, type: "recent"), as: :json

    assert_response :success
    assert_equal({ "approved" => false }, response.parsed_body)
  end

  test "filter with an unknown type falls back to the default branch" do
    # The controller does not special-case unknown type values; it falls
    # through to the `else` branch (all-time payments and articles).
    create_payment_with_state!(payer: @user, state: "paid", created_at: 2.weeks.ago)

    get api_valid_user_filter_path(user_id: @user.mixin_uuid, type: "bogus"), as: :json

    assert_response :success
    assert_equal({ "approved" => true }, response.parsed_body)
  end

  test "filter response shape is a JSON object with an `approved` boolean" do
    get api_valid_user_filter_path(user_id: SecureRandom.uuid), as: :json

    assert_response :success
    body = response.parsed_body
    assert_kind_of Hash, body
    assert_includes body.keys, "approved"
    assert_includes [ TrueClass, FalseClass ], body["approved"].class
  end
end
