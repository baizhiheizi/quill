# frozen_string_literal: true

# == Schema Information
#
# Table name: users
# Database name: primary
#
#  id                          :bigint           not null, primary key
#  authoring_subscribers_count :integer          default(0)
#  biography                   :text
#  blocked_at                  :datetime
#  blocking_count              :integer          default(0)
#  blocks_count                :integer          default(0)
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

  test "mixin_deposit_url formats correctly" do
    user = users(:author)

    assert_equal "mixin://transfer/#{user.mixin_uuid}", user.mixin_deposit_url
  end

  test "available_articles includes bought and own published articles" do
    user = users(:reader_one)

    articles = user.available_articles

    assert articles.all? { |a| a.is_a?(Article) }
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
end
