# frozen_string_literal: true

require "test_helper"

# Covers the `SoftDeletable` concern shared by `Comment` and `AccessToken`
# (and any future model that opts in via `include SoftDeletable`). The
# concern exposes three scopes (`without_deleted`, `only_deleted`,
# `with_deleted`), a `deleted?` predicate, and the four soft-delete /
# soft-undelete actions (the bang and non-bang variants of each).
#
# The existing `comment_test.rb` only checks `soft_delete!` round-tripping;
# `access_token_test.rb` only updates `deleted_at` directly. This file pins
# the contract: the bang variants raise on failure; the non-bang variants
# return a boolean; both restore cleanly via `soft_undelete*`; and the
# scopes are mutually consistent (kept ∧ only_deleted = ∅, kept ∪ only_deleted
# = with_deleted).
class SoftDeletableTest < ActiveSupport::TestCase
  setup do
    @comment = comments(:one)
    @token = access_tokens(:reader_token)
  end

  test "deleted? mirrors deleted_at" do
    assert_not @comment.deleted?
    assert_not @token.deleted?

    @comment.soft_delete!
    @token.soft_delete!

    assert_predicate @comment, :deleted?
    assert_predicate @token, :deleted?
  end

  test "soft_delete! stamps deleted_at and excludes the row from without_deleted" do
    @comment.soft_delete!

    assert_not_nil @comment.reload.deleted_at
    assert_nil Comment.without_deleted.find_by(id: @comment.id)
    assert_equal @comment, Comment.with_deleted.find_by(id: @comment.id)
  end

  test "soft_delete returns truthy on success" do
    assert @comment.soft_delete
    assert_predicate @comment.reload, :deleted?
  end

  test "soft_undelete! clears deleted_at and re-includes the row in without_deleted" do
    @comment.soft_delete!
    @comment.soft_undelete!

    assert_nil @comment.reload.deleted_at
    assert_not @comment.deleted?
    assert_equal @comment, Comment.without_deleted.find_by(id: @comment.id)
  end

  test "soft_undelete returns truthy on success" do
    @comment.soft_delete!
    assert @comment.soft_undelete
    assert_not @comment.reload.deleted?
  end

  test "soft_undelete! is a no-op (still succeeds) on a non-deleted record" do
    assert_nil @comment.deleted_at

    assert_nothing_raised do
      @comment.soft_undelete!
    end

    assert_nil @comment.reload.deleted_at
  end

  test "without_deleted and only_deleted are disjoint" do
    visible = Comment.without_deleted.pluck(:id)
    hidden = Comment.only_deleted.pluck(:id)

    assert_empty(visible & hidden, "kept and only_deleted rows overlap: #{(visible & hidden).inspect}")
  end

  test "without_deleted ∪ only_deleted covers every row that with_deleted returns" do
    every_id = Comment.with_deleted.pluck(:id)
    union = (Comment.without_deleted.pluck(:id) + Comment.only_deleted.pluck(:id)).uniq

    assert_equal every_id.sort, union.sort
  end

  test "with_deleted returns soft-deleted rows that the default scope hides" do
    @token.soft_delete!

    assert_nil AccessToken.kept.find_by(id: @token.id)
    assert_equal @token, AccessToken.with_deleted.find_by(id: @token.id)
  end

  test "round-trip soft_delete → soft_undelete returns the row to its prior state" do
    original_token = @token.value
    @token.soft_delete!
    kept_after_delete = AccessToken.kept.find_by(value: original_token)
    assert_nil kept_after_delete, "soft-deleted token should not be visible to the kept scope"

    @token.soft_undelete!
    recovered = AccessToken.kept.find_by(value: original_token)

    assert_equal @token, recovered
    assert_equal original_token, recovered.value
  end
end
