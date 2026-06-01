# frozen_string_literal: true

# == Schema Information
#
# Table name: users
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
end
