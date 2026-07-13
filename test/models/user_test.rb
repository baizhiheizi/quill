# frozen_string_literal: true

# == Schema Information
#
# Table name: users
# Database name: primary
#
#  id                          :bigint           not null, primary key
#  articles_count              :integer          default(0), not null
#  authoring_subscribers_count :integer          default(0)
#  biography                   :text
#  blocked_at                  :datetime
#  blocking_count              :integer          default(0)
#  blocks_count                :integer          default(0)
#  comments_count              :integer          default(0), not null
#  email                       :string
#  email_verified_at           :datetime
#  locale                      :string
#  mixin_uuid                  :uuid
#  name                        :string
#  reading_subscribers_count   :integer          default(0)
#  subscribers_count           :integer          default(0)
#  subscribing_count           :integer          default(0)
#  uid                         :string
#  validated_at                :datetime
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  mixin_id                    :string
#
# Indexes
#
#  index_users_on_email       (email) UNIQUE
#  index_users_on_mixin_id    (mixin_id)
#  index_users_on_mixin_uuid  (mixin_uuid) UNIQUE
#  index_users_on_name_trgm   (name) USING gin
#  index_users_on_uid         (uid) UNIQUE
#

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "to_param returns uid" do
    user = users(:author)

    assert_equal user.uid, user.to_param
  end

  test "bio returns biography when present" do
    user = users(:author)
    user.biography = "Custom bio"

    assert_equal "Custom bio", user.bio
  end

  test "bio falls back to authorization biography" do
    user = users(:author)
    user.biography = nil

    # User has no authorization in fixture, so falls back to default
    assert_equal I18n.t("activerecord.attributes.user.default_bio"), user.bio
  end

  test "short_uid returns first 6 chars for non-messenger users" do
    user = users(:author)

    # reader_one has uid "100002" which is not messenger
    assert_equal "100002", users(:reader_one).short_uid
  end

  test "block_user creates block action" do
    author = users(:author)
    reader = users(:reader_one)

    author.block_user(reader)

    assert Action.exists?(action_type: :block, target: reader, user: author)
  end

  test "block_user increments blocking_count on author" do
    author = users(:author)
    reader = users(:reader_one)
    initial_count = author.blocking_count

    author.block_user(reader)

    assert_equal initial_count + 1, author.blocking_count
  end

  test "unblock_user removes block action" do
    author = users(:author)
    reader = users(:reader_one)

    author.block_user(reader)
    author.unblock_user(reader)

    assert_not Action.exists?(action_type: :block, target: reader, user: author)
  end

  test "default_payment returns MixinPreOrder for messenger users" do
    assert_equal "MixinPreOrder", users(:reader_one).default_payment
  end

  # Fennec/mvm_eth login was removed, but those users and their
  # `UserAuthorization` rows are intentionally kept (see #1795) — they simply
  # have no working payment provider left until a new login path exists.
  test "default_payment returns nil for retired fennec/mvm_eth users" do
    fennec_user = User.create!(
      name: "Legacy Fennec",
      mixin_id: "fennec-1",
      mixin_uuid: SecureRandom.uuid,
      uid: "fennec-1"
    )
    UserAuthorization.create!(user: fennec_user, provider: :fennec, uid: "fennec-uid-1", raw: { "user_id" => "fennec-uid-1" })

    mvm_user = User.create!(
      name: "Legacy MVM",
      mixin_id: "mvm-1",
      mixin_uuid: SecureRandom.uuid,
      uid: "mvm-1"
    )
    UserAuthorization.create!(user: mvm_user, provider: :mvm_eth, uid: "mvm-uid-1", raw: { "user_id" => "mvm-uid-1" })

    assert_nil fennec_user.default_payment
    assert_nil mvm_user.default_payment
  end

  test "available_articles includes bought and own published articles" do
    user = users(:reader_one)

    articles = user.available_articles

    assert articles.all? { |a| a.is_a?(Article) }
  end

  test "available_articles dedupes across bought, own, and free pools" do
    user = users(:reader_one)

    # Behaviour: union of (bought and published) + (own and published) + (any free and published).
    # The previous Ruby .to_a + .to_a + .uniq implementation was correct in semantics but
    # materialised every free article in the database into memory before deduping. This test
    # pins the set-equivalence so the SQL rewrite stays correct.
    expected_ids = (
      user.bought_articles.only_published.pluck(:id) +
        user.articles.only_published.pluck(:id) +
        Article.only_free.only_published.where.not(id: user.bought_articles.only_published.select(:id))
          .where.not(id: user.articles.only_published.select(:id)).pluck(:id)
    ).uniq.sort

    actual_ids = user.available_articles.distinct.pluck(:id).sort

    assert_equal expected_ids, actual_ids
  end

  test "requires name, mixin_id, mixin_uuid, uid" do
    user = User.new

    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
    assert_includes user.errors[:mixin_id], "can't be blank"
    assert_includes user.errors[:mixin_uuid], "can't be blank"
    assert_includes user.errors[:uid], "can't be blank"
  end

  test "uid must be unique" do
    existing_user = users(:author)
    new_user = User.new(uid: existing_user.uid, name: "Test", mixin_id: "999999", mixin_uuid: SecureRandom.uuid)

    assert_not new_user.valid?
    assert_includes new_user.errors[:uid], "has already been taken"
  end

  # Reading #wallet_id must not provision a new Mixin user — provisioning now
  # costs 0.5 USDT (MixinBot::CREATE_USER_BILLING_INCREMENT). See #1797.
  test "wallet_id returns nil and does not create a wallet when none exists" do
    user = users(:author)
    user.update!(wallet: nil)
    initial_count = MixinNetworkUser.count

    assert_nothing_raised { assert_nil user.wallet_id }
    assert_nil user.reload.wallet, "wallet_id read must not create a MixinNetworkUser"
    assert_equal initial_count, MixinNetworkUser.count,
                 "wallet_id read must not create any MixinNetworkUser"
  end

  test "wallet_id returns the existing wallet uuid when one is present" do
    wallet = mixin_network_users(:article_wallet)
    user = users(:author)
    user.update!(wallet: wallet)

    assert_equal wallet.uuid, user.wallet_id
  end

  test "order_by_articles_count includes all users and orders by the cached counter column" do
    # `author` fixture has an article; `reader_one` and `reader_two` do not.
    # The scope is now a simple `ORDER BY articles_count DESC, id ASC` over
    # the `users.articles_count` counter-cache column, so we need to seed
    # that column to reproduce the old INNER-Join-correctness test.
    users(:author).update_column(:articles_count, users(:author).articles.count)
    users(:reader_one).update_column(:articles_count, 0)

    rows = User.order_by_articles_count.to_a

    assert_includes rows.map(&:id), users(:author).id
    assert_includes rows.map(&:id), users(:reader_one).id
    assert_includes rows.map(&:id), users(:reader_two).id
    assert_equal users(:author).id, rows.first.id
  end

  test "order_by_articles_count does not use LEFT JOIN or GROUP BY" do
    sql = User.order_by_articles_count.to_sql

    assert_not_includes sql, "JOIN", "order_by_articles_count should not need a JOIN — it sorts by users.articles_count"
    assert_not_includes sql, "GROUP BY"
  end

  test "active authors joins qualifying articles and returns unique users" do
    author = users(:author)
    author.articles.update_all(created_at: 1.day.ago, orders_count: 1)

    rows = User.active.to_a
    row_ids = rows.map(&:id)

    assert_includes row_ids, author.id
    assert_equal row_ids.uniq, row_ids
  end

  test "order_by_comments_count includes all users and orders by the cached counter column" do
    users(:author).update_column(:comments_count, users(:author).comments.count)
    users(:reader_one).update_column(:comments_count, 0)

    rows = User.order_by_comments_count.to_a

    assert_includes rows.map(&:id), users(:author).id
    assert_includes rows.map(&:id), users(:reader_one).id
    assert_equal users(:author).id, rows.first.id
  end

  test "order_by_comments_count does not use LEFT JOIN or GROUP BY" do
    sql = User.order_by_comments_count.to_sql

    assert_not_includes sql, "JOIN", "order_by_comments_count should not need a JOIN — it sorts by users.comments_count"
    assert_not_includes sql, "GROUP BY"
  end

  test "article counter cache is maintained on author" do
    author = users(:author)
    initial = author.articles_count

    article = Article.new(
      uuid: SecureRandom.uuid,
      title: "Counter-cache test",
      intro: "intro",
      author: author,
      asset_id: SecureRandom.uuid,
      price: 0.0001,
      state: :published
    )
    article.content = "<p>test</p>"
    article.save!

    assert_equal initial + 1, author.reload.articles_count
  end

  test "article counter cache is decremented on destroy" do
    author = users(:author)
    article = author.articles.first
    before = author.reload.articles_count

    article.destroy!

    assert_equal before - 1, author.reload.articles_count
  end

  test "comment counter cache is maintained on author" do
    author = users(:author)
    article = author.articles.first
    initial = author.reload.comments_count

    article.comments.create!(author: author, legacy_markdown_content: "test")

    assert_equal initial + 1, author.reload.comments_count
  end

  test "comment counter cache is decremented on destroy" do
    author = users(:author)
    article = author.articles.first
    comment = article.comments.create!(author: author, legacy_markdown_content: "test")
    before = author.reload.comments_count

    comment.destroy!

    assert_equal before - 1, author.reload.comments_count
  end

  test "statable articles_count reads the column without a SQL query" do
    author = users(:author)
    author.update_column(:articles_count, 42)

    sql_counter = 0
    callback = ->(*, payload) { sql_counter += 1 unless payload[:name] == "SCHEMA" }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      assert_equal 42, author.articles_count
    end

    assert_equal 0, sql_counter, "statable#articles_count should not run SQL — it reads the cached column"
  end

  test "statable comments_count reads the column without a SQL query" do
    author = users(:author)
    author.update_column(:comments_count, 7)

    sql_counter = 0
    callback = ->(*, payload) { sql_counter += 1 unless payload[:name] == "SCHEMA" }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      assert_equal 7, author.comments_count
    end

    assert_equal 0, sql_counter, "statable#comments_count should not run SQL — it reads the cached column"
  end

  test "order_by_orders_total includes users with zero orders via LEFT JOIN" do
    rows = User.order_by_orders_total.to_a

    assert_includes rows.map(&:id), users(:author).id
    assert_includes rows.map(&:id), users(:reader_one).id
    assert_equal 0.0, rows.find { |u| u.id == users(:reader_one).id }.attributes["orders_total"].to_f
  end

  test "order_by_revenue_total includes users with no transfers via LEFT JOIN" do
    rows = User.order_by_revenue_total.to_a

    assert_includes rows.map(&:id), users(:author).id
    assert_includes rows.map(&:id), users(:reader_one).id
    assert_equal 0.0, rows.find { |u| u.id == users(:reader_one).id }.attributes["revenue_total"].to_f
  end

  test "twitter_connected requires a usable username" do
    user = users(:author)
    user.user_authorizations.create!(
      provider: :twitter,
      uid: "twitter-user-id",
      raw: { "id" => "twitter-user-id", "name" => "Author" }
    )

    assert_not user.twitter_connected?
    assert_nil user.twitter_profile_url
  end

  test "twitter_profile_url builds a profile link from stored username" do
    user = users(:reader_one)
    user.user_authorizations.create!(
      provider: :twitter,
      uid: "reader-twitter-id",
      raw: { "id" => "reader-twitter-id", "username" => "reader_one" }
    )

    assert user.twitter_connected?
    assert_equal "https://twitter.com/reader_one", user.twitter_profile_url
  end

  test "twitter_profile_url ignores malformed username values" do
    user = users(:reader_two)
    user.user_authorizations.create!(
      provider: :twitter,
      uid: "reader-two-twitter-id",
      raw: { "id" => "reader-two-twitter-id", "username" => 123 }
    )

    assert_not user.twitter_connected?
    assert_nil user.twitter_profile_url
  end

  test "avatar_image_url returns nil when user has no real avatar" do
    user = users(:reader_one)

    assert_nil user.avatar_image_url
  end

  test "avatar_url falls back to platform icon when user has no real avatar" do
    user = users(:reader_one)

    assert_equal User.default_avatar_url, user.avatar_url
  end

  test "avatar_image_url returns oauth avatar when present" do
    user = users(:author)

    assert_equal "https://example.com/avatar.png", user.avatar_image_url
  end

  test "avatar_image_thumb returns oauth thumb url when no attached avatar" do
    user = users(:author)
    user.user_authorizations.find_by!(provider: :mixin).update!(
      raw: { "avatar_url" => "https://example.com/avatar_s256" }
    )

    assert_equal "https://example.com/avatar_s64", user.avatar_image_thumb
  end

  test "avatar_image_thumb returns variant url when avatar attached" do
    user = users(:author)
    user.avatar.attach(
      io: File.open(Rails.root.join("test/fixtures/files/avatar.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )

    thumb_url = user.avatar_image_thumb

    assert thumb_url.present?
    assert_includes thumb_url, Settings.storage.endpoint
  end

  test "removed dead methods stay removed" do
    refute_includes User.instance_methods(false), :mixin_deposit_url
    refute_includes User.instance_methods(false), :public_key
  end
end
