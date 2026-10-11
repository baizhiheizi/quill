# frozen_string_literal: true

# Issue #2107 — `ActionView::Template::Error: incompatible character
# encodings: BINARY (ASCII-8BIT) and UTF-8`.
#
# `ActionView::OutputBuffer#<<` raises `Encoding::CompatibilityError` when a
# UTF-8 output buffer receives a binary-tagged string carrying non-ASCII
# bytes, so one badly-encoded string anywhere in a render 500s that whole
# page for every visitor (2026-09-11: 14 users hit on `/articles` while one
# such string sat in the feed render).
#
# Ruby treats ASCII-8BIT as "bytes with unknown encoding", so re-tagging to
# UTF-8 preserves the content byte-for-byte; `scrub!` only kicks in when the
# bytes are not valid UTF-8, replacing the broken sequences with U+FFFD.
#
# Compiled templates emit `@output_buffer.append=(...)` / `.concat(...)`,
# which in ActionView are aliases of `<<` created in the class body. Aliased
# copies bypass a prepended `<<`, so each alias is shadowed here explicitly.
module OutputBufferUtf8
  def <<(value)
    super(normalize_to_utf8(value))
  end

  def concat(value)
    self << value
  end

  def append=(value)
    self << value
  end

  def safe_append=(value)
    super(normalize_to_utf8(value))
  end

  def safe_expr_append=(value)
    super(normalize_to_utf8(value))
  end

  private

  def normalize_to_utf8(value)
    return value unless value.respond_to?(:encoding) && value.encoding == Encoding::ASCII_8BIT

    value = value.dup.force_encoding(Encoding::UTF_8)
    value.scrub! unless value.valid_encoding?
    value
  end
end

ActionView::OutputBuffer.prepend(OutputBufferUtf8)
