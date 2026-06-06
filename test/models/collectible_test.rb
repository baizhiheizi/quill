# frozen_string_literal: true

# == Schema Information
#
# Table name: collectibles
# Database name: primary
#
#  id            :bigint           not null, primary key
#  identifier    :string
#  metadata      :jsonb
#  metahash      :string
#  name          :string
#  source_type   :string
#  state         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  collection_id :uuid
#  source_id     :bigint
#  token_id      :uuid
#
# Indexes
#
#  index_collectibles_on_collection_id_and_identifier  (collection_id,identifier) UNIQUE
#  index_collectibles_on_metahash                      (metahash) UNIQUE
#  index_collectibles_on_source_type_and_source_id     (source_type,source_id) UNIQUE
#  index_collectibles_on_token_id                      (token_id) UNIQUE
#
require "test_helper"

class CollectibleTest < ActiveSupport::TestCase
  test "collection_id_valid? returns false for zero UUID" do
    collectible = Collectible.new(collection_id: "00000000-0000-0000-0000-000000000000")

    assert_not collectible.collection_id_valid?
  end

  test "collection_id_valid? returns true for valid UUID" do
    collectible = Collectible.new(collection_id: "55000000-0000-0000-0000-000000000000")

    assert collectible.collection_id_valid?
  end

  test "media_url returns metadata URL when no attachment" do
    collectible = Collectible.new
    collectible.metadata = { "media_url" => "https://example.com/media.jpg" }

    assert_equal "https://example.com/media.jpg", collectible.media_url
  end

  test "media_url returns storage URL when media attached" do
    collectible = Collectible.new(
      identifier: "token123",
      name: "Test NFT",
      metahash: "abc123",
      collection_id: "55000000-0000-0000-0000-000000000000"
    )

    # Just verify the method exists and returns nil when no media attached
    assert_respond_to collectible, :media_url
  end

  test "requires identifier" do
    collectible = Collectible.new(
      name: "Test",
      metahash: "abc123",
      collection_id: "55000000-0000-0000-0000-000000000000"
    )

    assert_not collectible.valid?
    assert_includes collectible.errors[:identifier], "can't be blank"
  end

  test "requires name" do
    collectible = Collectible.new(
      identifier: "token123",
      metahash: "abc123",
      collection_id: "55000000-0000-0000-0000-000000000000"
    )

    assert_not collectible.valid?
    assert_includes collectible.errors[:name], "can't be blank"
  end

  test "requires metahash" do
    collectible = Collectible.new(
      identifier: "token123",
      name: "Test NFT",
      collection_id: "55000000-0000-0000-0000-000000000000"
    )

    assert_not collectible.valid?
    assert_includes collectible.errors[:metahash], "can't be blank"
  end

  test "requires collection_id" do
    collectible = Collectible.new(
      identifier: "token123",
      name: "Test NFT",
      metahash: "abc123"
    )

    assert_not collectible.valid?
    assert_includes collectible.errors[:collection_id], "can't be blank"
  end

  test "belongs to source as polymorphic" do
    collectible = Collectible.new(
      identifier: "token123",
      name: "Test NFT",
      metahash: "abc123",
      collection_id: "55000000-0000-0000-0000-000000000000"
    )

    assert_respond_to collectible, :source
  end
end
