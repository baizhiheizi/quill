# frozen_string_literal: true

class RichTextRenderService
  include HtmlPostProcessor

  def initialize(rich_text, **kargs)
    @html =
      case rich_text
      when ActionText::RichText
        rich_text.body.to_html
      when ActionText::Content
        rich_text.to_html
      else
        rich_text.to_s
      end
    @type = kargs[:type] || :default
  end

  def self.call(*, **kargs)
    new(*, **kargs).call
  end

  def call
    case @type
    when :default
      escape_iframes
    when :full
      parse_paragraph
      parse_link
      parse_table
      add_attributes_to_images
      add_scroll_to_comment_attributes
      escape_iframes
    end

    serialize!
  end
end
