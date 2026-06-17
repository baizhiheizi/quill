# frozen_string_literal: true

require "test_helper"

class UserHelperTest < ActionView::TestCase
  test "avatar_initials returns two initials for multi-word latin names" do
    assert_equal "TA", avatar_initials("Test Author")
  end

  test "avatar_initials returns one initial for single-word latin names" do
    assert_equal "A", avatar_initials("Alice")
  end

  test "avatar_initials returns first grapheme for cjk names" do
    assert_equal "张", avatar_initials("张三")
  end

  test "avatar_initials returns question mark for blank names" do
    assert_equal "?", avatar_initials("")
    assert_equal "?", avatar_initials(nil)
  end
end
