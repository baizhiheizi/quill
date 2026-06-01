# frozen_string_literal: true

require "test_helper"

class CommentPolicyTest < ActiveSupport::TestCase
  setup do
    @article = articles(:published_paid)
    @free_article = articles(:published_free)
    @reader = users(:reader_one)
    @author = users(:author)
  end

  test "create? allows readers on published articles" do
    assert CommentPolicy.new(@reader, @free_article).create?
  end

  test "create? denies guests" do
    refute CommentPolicy.new(nil, @free_article).create?
  end

  test "create? denies commenting on draft articles without access" do
    draft = articles(:draft)

    refute CommentPolicy.new(@reader, draft).create?
  end

  test "vote? allows authorized non-author readers" do
    comment = comments(:one)

    with_quill_bot_stub do
      create_buy_order!(article: @article, buyer: @reader)
    end

    assert CommentPolicy.new(@reader, comment).vote?
  end

  test "vote? denies comment author" do
    comment = comments(:one)

    refute CommentPolicy.new(comment.author, comment).vote?
  end

  test "vote? denies guests" do
    comment = comments(:one)

    refute CommentPolicy.new(nil, comment).vote?
  end
end
