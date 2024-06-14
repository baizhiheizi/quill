# frozen_string_literal: true

class MarkdownRenderService
  IFRAME_SRC_WHITE_LIST_REGEX = [%r{\Ahttps://(www.)?youtube\.com/\S+\z}].freeze

  class HTMLWithTocRender < Redcarpet::Render::HTML
    def preprocess(document)
      @document = document
    end

    def paragraph(content)
      if ['[TOC]', '{:toc}'].include?(content)
        toc_render = Redcarpet::Render::HTML_TOC.new(nesting_level: 4)
        parser     = Redcarpet::Markdown.new(toc_render)
        parser.render @document
      else
        render = Redcarpet::Render::HTML.new(
          with_toc_data: true,
          hard_wrap: true,
          prettify: true
        )
        parser = Redcarpet::Markdown.new render
        parser.render content
      end
    end
  end

  def initialize(content, **kargs)
    @content = content.to_s
    @type = kargs[:type] || :default
  end

  def self.call(*, **kargs)
    new(*, **kargs).call
  end

  def call
    # @html = Redcarpet::Markdown.new(
    #   HTMLWithTocRender.new(
    #     with_toc_data: true,
    #     hard_wrap: true,
    #     prettify: true
    #   ),
    #   autolink: true,
    #   disable_indented_code_blocks: true,
    #   tables: true,
    #   fenced_code_blocks: true,
    #   space_after_headers: true,
    #   lax_spacing: false,
    #   quote: true,
    #   underline: true,
    #   highlight: true,
    #   footnotes: true,
    #   strikethrough: true
    # ).render @content.to_s

    @html = Kramdown::Document.new(@content, input: 'GFM').to_html

    case @type
    when :default
      escape_iframes
    when :full
      parse_paragraph
        .parse_link
        .parse_table
        .add_attributes_to_images
        .parse_mention_user
        .add_scroll_to_comment_attributes
        .escape_iframes
    end

    @html
  end

  def parse_mention_user
    self
  end

  def parse_link
    doc = Nokogiri::HTML.fragment(@html)
    doc.css('a').each do |a|
      a['target'] = '_blank' if a['data-turbo-method'].blank?
    end
    @html = doc.to_html

    self
  end

  def parse_paragraph
    doc = Nokogiri::HTML.fragment(@html)
    doc.css('p').each do |p|
      p['class'] = 'text-ellipsis overflow-x-hidden'
    end
    @html = doc.to_html

    self
  end

  def parse_table
    doc = Nokogiri::HTML.fragment(@html)
    doc.css('table').each do |table|
      table['class'] = 'min-width-max'
      table.wrap('<div class="overflow-x-scroll"></div>')
    end
    @html = doc.to_html

    self
  end

  def add_attributes_to_images
    doc = Nokogiri::HTML.fragment(@html)
    doc.css('img').each do |img|
      src = img.attr('src')

      case src
      when %r{/rails/active_storage/blobs/\S+}
        img['src'] = src.gsub(/\.\S+\z/, '')
      when %r{blob://\S+}
        key = src.gsub('blob://', '').split('/').first
        blob = ActiveStorage::Blob.find_by(key:)
        img['src'] = blob.url if blob.present?
      end

      size = Rails.cache.fetch(img['src']) do
        FastImage.size img['src']
      end
      Rails.cache.delete(img['src']) if size.blank?

      size ||= []

      img.wrap <<~TAG
        <a 
          class='photoswipe' 
          data-pswp-src='#{img['src']}' 
          data-pswp-width='#{size.first}' 
          data-pswp-height='#{size.last}' 
          href='#{img['src']}' 
          target='_blank'
        >
      TAG

      img['class'] = 'max-w-full mx-auto bg-zinc-50'
      img['width'] = size.first if size.first.present?
      img['height'] = size.last if size.last.present?
      img['loading'] = 'lazy'
    end
    @html = doc.to_html

    self
  end

  def add_scroll_to_comment_attributes
    doc = Nokogiri::HTML.fragment(@html)
    doc.css('a').each do |link|
      href = link.attr('href')
      if href&.match?(/\A#comment/)
        link['data-turbo-method'] = 'post'
        link['href'] = "/view_modals?type=comment_form&quote_comment_id=#{href.underscore.split('_').last}"
      end
    end
    @html = doc.to_html

    self
  end

  def escape_iframes
    doc = Nokogiri::HTML.fragment(@html)
    doc.css('iframe').each do |iframe|
      iframe['class'] = 'w-full h-auto'
      iframe.remove unless iframe['src']&.match?(Regexp.union(IFRAME_SRC_WHITE_LIST_REGEX))
    end
    @html = doc.to_html

    self
  end
end
