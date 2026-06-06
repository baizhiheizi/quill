# frozen_string_literal: true

# == Schema Information
#
# Table name: comments
# Database name: primary
#
#  id                      :bigint           not null, primary key
#  commentable_type        :string
#  comments_count          :integer          default(0)
#  deleted_at              :datetime
#  downvotes_count         :integer          default(0)
#  legacy_markdown_content :string
#  upvotes_count           :integer          default(0)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  author_id               :bigint
#  commentable_id          :bigint
#  quote_comment_id        :bigint
#
# Indexes
#
#  index_comments_on_author_id                            (author_id)
#  index_comments_on_commentable_type_and_commentable_id  (commentable_type,commentable_id)
#  index_comments_on_quote_comment_id                     (quote_comment_id)
#

require "test_helper"

class CommentTest < ActiveSupport::TestCase
  test "content_length_limit returns 1000" do
    assert_equal 1000, Comment.content_length_limit
  end

  test "soft delete removes from normal queries" do
    comment = comments(:one)

    comment.soft_delete!

    assert_predicate comment, :deleted?
    assert_nil Comment.without_deleted.find_by(id: comment.id)
    assert_equal comment, Comment.with_deleted.find_by(id: comment.id)
  end

  test "soft delete preserves record" do
    comment = comments(:one)
    comment_id = comment.id

    comment.soft_delete!

    assert Comment.with_deleted.find_by(id: comment_id)
  end

  test "rejects comment from blocked user" do
    article = articles(:published_paid)
    author = article.author
    blocked_user = users(:reader_one)

    author.block_user(blocked_user)

    comment = Comment.new(
      author: blocked_user,
      commentable: article,
      content: "test comment"
    )

    assert_not comment.valid?
    assert_includes comment.errors[:author], "blocked"
  end

  test "allows comment from non-blocked user" do
    article = articles(:published_paid)
    reader = users(:reader_one)

    comment = Comment.new(
      author: reader,
      commentable: article,
      content: "test comment"
    )

    assert comment.valid?
  end

  test "belongs to commentable as polymorphic" do
    comment = comments(:one)

    assert_instance_of Article, comment.commentable
  end

  test "has many replies through quote_comment" do
    comment = comments(:one)

    assert_respond_to comment, :comments
  end

  test "reply belongs to parent comment" do
    comment = comments(:one)
    reply = comments(:two)

    assert_equal comment, reply.quote_comment
  end
end
