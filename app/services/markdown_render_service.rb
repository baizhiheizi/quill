# frozen_string_literal: true

class MarkdownRenderService
  IFRAME_SRC_WHITE_LIST_REGEX = [%r{\Ahttps://(www.)?youtube\.com/\S+\z}].freeze

  class HTMLWithTocRender < Redcarpet::Render::HTML
    def preprocess(document)
      @document = document
    end

    def paragraph(content)
      return content unless ['[TOC]', '{:toc}'].include?(content)

      toc_render = Redcarpet::Render::HTML_TOC.new(nesting_level: 4)
      parser     = Redcarpet::Markdown.new(toc_render)

      parser.render(@document)
    end
  end

  def call(content, type: :default)
    @html = Redcarpet::Markdown.new(
      HTMLWithTocRender.new(
        with_toc_data: true,
        hard_wrap: true,
        prettify: true
      ),
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
    escape_iframes

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

  def escape_iframes
    doc = Nokogiri::HTML.fragment(@html)
    doc.css('iframe').each do |iframe|
      iframe['class'] = 'w-full h-auto'
      iframe.remove unless iframe['src'].match?(Regexp.union(IFRAME_SRC_WHITE_LIST_REGEX))
    end
    @html = doc.to_html

    self
  end
end
