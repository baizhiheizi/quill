# frozen_string_literal: true

class MarkdownRenderService
  def call(content, type: :default)
    @html = Redcarpet::Markdown.new(
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

    case type
    when :article
      parse_mention_user
    when :comment
      add_scroll_to_comment_attributes
    end

    add_attributes_to_images

    @html
  end

  private

  def parse_mention_user
  end

  def add_attributes_to_images
    doc = Nokogiri::HTML.fragment(@html)
    doc.css('img').each do |img|
      src = img.attr('src')
      img['src'] = src.gsub(/\.\S+\z/, '') if src.match?(%r{/rails/active_storage/blobs/\S+})
      img['class'] = 'max-w-full mx-auto'
      img['loading'] = 'lazy'
      img.wrap("<a class='photoswipe' data-pswp-src='#{img['src']}' href='#{img['src']}' target='_blank'>")
    end
    @html = doc.to_html

    self
  end

  def add_scroll_to_comment_attributes
    doc = Nokogiri::HTML.fragment(@html)
    doc.css('a').each do |link|
      href = link.attr('href')
      if href.match?(/\A#comment/)
        link['data-controller'] = 'scroll-to'
        link['href'] = href.underscore
      end
    end
    @html = doc.to_html

    self
  end
end
