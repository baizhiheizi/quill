# frozen_string_literal: true

require "test_helper"

class CommentPolicyTest < ActiveSupport::TestCase
  setup do
    @article = articles(:published_paid)
    @reader = users(:reader_one)
    @author = users(:author)
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
