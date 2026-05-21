# frozen_string_literal: true

class RichTextRenderService
  IFRAME_SRC_WHITE_LIST_REGEX = MarkdownRenderService::IFRAME_SRC_WHITE_LIST_REGEX

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

    @html
  end

  private

  def parse_link
    doc = Nokogiri::HTML.fragment(@html)
    doc.css("a").each do |a|
      a["target"] = "_blank" if a["data-turbo-method"].blank?
    end
    @html = doc.to_html
  end

  def parse_paragraph
    doc = Nokogiri::HTML.fragment(@html)
    doc.css("p").each do |p|
      p["class"] = "text-ellipsis overflow-x-hidden"
    end
    @html = doc.to_html
  end

  def parse_table
    doc = Nokogiri::HTML.fragment(@html)
    doc.css("table").each do |table|
      table["class"] = "min-width-max"
      table.wrap('<div class="overflow-x-scroll"></div>')
    end
    @html = doc.to_html
  end

  def add_attributes_to_images
    doc = Nokogiri::HTML.fragment(@html)
    doc.css("img").each do |img|
      src = img.attr("src")

      if src&.match?(%r{/rails/active_storage/blobs/\S+})
        img["src"] = src.gsub(/\.\S+\z/, "")
      end

      size = Rails.cache.fetch(img["src"]) do
        FastImage.size img["src"]
      end
      Rails.cache.delete(img["src"]) if size.blank?

      size ||= []

      img.wrap <<~TAG
        <a#{' '}
          class='photoswipe'#{' '}
          data-pswp-src='#{img['src']}'#{' '}
          data-pswp-width='#{size.first}'#{' '}
          data-pswp-height='#{size.last}'#{' '}
          href='#{img['src']}'#{' '}
          target='_blank'
        >
      TAG

      img["class"] = "max-w-full mx-auto bg-zinc-50"
      img["width"] = size.first if size.first.present?
      img["height"] = size.last if size.last.present?
      img["loading"] = "lazy"
    end
    @html = doc.to_html
  end

  def add_scroll_to_comment_attributes
    doc = Nokogiri::HTML.fragment(@html)
    doc.css("a").each do |link|
      href = link.attr("href")
      if href&.match?(/\A#comment/)
        link["data-turbo-method"] = "post"
        link["href"] = "/view_modals?type=comment_form&quote_comment_id=#{href.underscore.split('_').last}"
      end
    end
    @html = doc.to_html
  end

  def escape_iframes
    doc = Nokogiri::HTML.fragment(@html)
    doc.css("iframe").each do |iframe|
      iframe["class"] = "w-full h-auto"
      iframe.remove unless iframe["src"]&.match?(Regexp.union(IFRAME_SRC_WHITE_LIST_REGEX))
    end
    @html = doc.to_html
  end
end
