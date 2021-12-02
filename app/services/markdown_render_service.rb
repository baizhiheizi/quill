# frozen_string_literal: true

class MarkdownRenderService
  def call(content)
    Redcarpet::Markdown.new(
      Redcarpet::Render::HTML,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      space_after_headers: true,
      lax_spacing: true,
      quote: true,
      underline: true,
      highlight: true,
      footnotes: true,
      strikethrough: true
    ).render content.to_s
  end
end
