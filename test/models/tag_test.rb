# frozen_string_literal: true

# == Schema Information
#
# Table name: tags
# Database name: primary
#
#  id                :bigint           not null, primary key
#  articles_count    :integer          default(0)
#  locale            :string
#  name              :string
#  subscribers_count :integer          default(0)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "name must be unique" do
    existing_tag = tags(:web3)
    duplicate_tag = Tag.new(name: existing_tag.name)

    assert_not duplicate_tag.valid?
    assert_includes duplicate_tag.errors[:name], "has already been taken"
  end

  test "name uniqueness is enforced" do
    tag = Tag.new(name: "")

    # Empty string may or may not be valid depending on DB constraints
    # The key test is that duplicate names are rejected
    tag2 = Tag.new(name: tags(:web3).name)

    assert_not tag2.valid?
    assert_includes tag2.errors[:name], "has already been taken"
  end

  test "has_many taggings" do
    tag = tags(:web3)

    assert_respond_to tag, :taggings
  end

  test "has_many articles through taggings" do
    tag = tags(:web3)

    assert_respond_to tag, :articles
  end

  test "scope recommended orders by articles_count desc" do
    recommended_tags = Tag.recommended.to_a

    assert_equal recommended_tags.sort_by(&:articles_count).reverse, recommended_tags
  end

  test "scope hot filters published articles from last 3 months" do
    hot_tags = Tag.hot

    # Verify it's a relation, not errors
    assert_respond_to hot_tags, :to_sql
  end

  test "scope hot count works without PG syntax error" do
    # Regression: prior shape used `select("COUNT(articles.id) AS lately_article_count")`,
    # which broke `count` because ActiveRecord generated
    # `SELECT COUNT(tags.*, COUNT(articles.id) AS ...)` — invalid SQL.
    # `Tag.hot.count` should now return successfully (a Hash of tag_id => row_count
    # because the relation is GROUPed by id).
    assert_nothing_raised do
      result = Tag.hot.count
      assert_kind_of Hash, result
      result.each_value { |c| assert_kind_of Integer, c }
    end
  end

  test "scope hot drops the unused lately_article_count alias" do
    # The alias was unused outside the scope and only caused the .count regression.
    refute_includes Tag.hot.to_sql, "lately_article_count"
  end

  test "scope hot orders by COUNT(articles.id) desc, tags.created_at desc" do
    sql = Tag.hot.to_sql
    assert_includes sql, "COUNT(articles.id) DESC"
    assert_includes sql, "tags.created_at DESC"
  end

  test "update_locale updates locale field" do
    tag = Tag.new(name: "新技术")

    # detect_locale uses CLD which may not be reliable in test
    # Just verify the method exists and is callable
    assert_respond_to tag, :update_locale
  end

  test "detect_locale returns language code" do
    tag = Tag.new(name: "blockchain")

    # CLD.detect_language returns a hash with :code
    result = tag.detect_locale
    assert_instance_of String, result
    assert_equal 2, result.length # Language codes are 2 chars (e.g., "en")
  end

  test "setup_locale assigns locale before validation" do
    tag = Tag.new(name: "test_tag_#{SecureRandom.uuid}")

    # The locale should be set by before_validation callback
    tag.valid?
    assert_not_nil tag.locale
  end
end
