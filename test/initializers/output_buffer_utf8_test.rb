# frozen_string_literal: true

require "test_helper"

# Issue #2107 — a binary-tagged (ASCII-8BIT) string with non-ASCII bytes
# used to raise Encoding::CompatibilityError the moment it met a UTF-8
# output buffer, 500ing the whole page (see the initializer for details).
class OutputBufferUtf8Test < ActiveSupport::TestCase
  test "appending a binary-tagged non-ASCII string no longer raises" do
    buffer = ActionView::OutputBuffer.new
    binary = "中文标题".dup.force_encoding(Encoding::ASCII_8BIT)

    buffer << binary

    assert_equal Encoding::UTF_8, buffer.to_s.encoding
    assert_equal "中文标题", buffer.to_s
  end

  test "invalid UTF-8 bytes are scrubbed instead of raising" do
    buffer = ActionView::OutputBuffer.new
    binary = "中\xFF文".dup.force_encoding(Encoding::ASCII_8BIT)

    buffer << binary

    assert_equal "中�文", buffer.to_s
  end

  test "safe and unsafe append paths both accept binary-tagged strings" do
    buffer = ActionView::OutputBuffer.new

    buffer.safe_append= "中文".dup.force_encoding(Encoding::ASCII_8BIT)
    buffer.safe_expr_append= "简介".dup.force_encoding(Encoding::ASCII_8BIT)

    assert_equal "中文简介", buffer.to_s
  end

  # Compiled templates emit `@output_buffer.append=(...)` / `.concat(...)`,
  # which are class-body aliases of `<<` — the aliases must be patched too.
  test "concat and append= aliases accept binary-tagged strings" do
    buffer = ActionView::OutputBuffer.new

    buffer.concat("标题".dup.force_encoding(Encoding::ASCII_8BIT))
    buffer.append= "简介".dup.force_encoding(Encoding::ASCII_8BIT)

    assert_equal "标题简介", buffer.to_s
  end

  test "non-string values keep their original behavior" do
    buffer = ActionView::OutputBuffer.new

    buffer << 5
    buffer << nil
    buffer << "utf8"

    assert_equal "5utf8", buffer.to_s
  end

  test "a view render containing a binary-tagged string succeeds" do
    html = ArticlesController.renderer.new.render(
      inline: "<p><%= '中文内容'.dup.force_encoding(Encoding::BINARY) %></p>"
    )

    # The rendered document may itself be binary-tagged, so re-tag before
    # the UTF-8 needle comparison.
    assert_includes html.dup.force_encoding(Encoding::UTF_8), "中文内容"
  end
end
