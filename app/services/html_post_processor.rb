# frozen_string_literal: true

# Shared Nokogiri-based HTML post-processing helpers used by
# MarkdownRenderService and RichTextRenderService. Methods mutate
# @html in place and return `self` so they can be chained.
module HtmlPostProcessor
  # Allow-list of iframe src patterns kept by `escape_iframes`. Only
  # YouTube is currently trusted; everything else is stripped.
  IFRAME_SRC_WHITE_LIST_REGEX = [ %r{\Ahttps://(www.)?youtube\.com/\S+\z} ].freeze

  def parse_link
    transform("a") do |a|
      a["target"] = "_blank" if a["data-turbo-method"].blank?
    end
  end

  # `overflow-x-hidden` alone (without `overflow-y`) makes browsers compute
  # `overflow-y` as `auto` per the CSS overflow spec, which paints a
  # persistent (if empty) vertical scrollbar on every paragraph on
  # platforms with classic, non-overlay scrollbars. `break-words` prevents
  # long unbroken strings (e.g. URLs) from overflowing horizontally without
  # touching either axis's overflow.
  def parse_paragraph
    transform("p") { |p| p["class"] = "break-words" }
  end

  def parse_table
    transform("table") do |table|
      table["class"] = "min-width-max"
      table.wrap('<div class="overflow-x-scroll"></div>')
    end
  end

  def add_scroll_to_comment_attributes
    transform("a") do |link|
      href = link.attr("href")
      if href&.match?(/\A#comment/)
        link["data-turbo-method"] = "post"
        link["href"] = "/view_modals?type=comment_form&quote_comment_id=#{href.underscore.split('_').last}"
      end
    end
  end

  def escape_iframes
    transform("iframe") do |iframe|
      iframe["class"] = "w-full h-auto"
      iframe.remove unless iframe["src"]&.match?(Regexp.union(IFRAME_SRC_WHITE_LIST_REGEX))
    end
  end

  # `add_attributes_to_images` does enough non-CSS work (FastImage fetch,
  # photoswipe anchor wrap, conditional attribute writes) that it stays as
  # its own block, but the parse/serialize/return-self prologue and epilogue
  # are still factored out below.
  def add_attributes_to_images
    doc = Nokogiri::HTML.fragment(@html)
    doc.css("img").each { |img| decorate_image(img) }
    @html = doc.to_html

    self
  end

  # Hook for subclasses to rewrite an image's src before caching/fetching
  # the image dimensions. Default handles Active Storage blob URLs by
  # stripping trailing file extensions.
  def normalize_image_src(img, src)
    return if src.blank?

    if src.match?(%r{/rails/active_storage/blobs/\S+})
      img["src"] = src.gsub(/\.\S+\z/, "")
    end
  end

  private

  # Common parse / transform / serialize / return-self pipeline used by
  # every transform-style post-processor above. Yields each matched
  # element to the block for in-place mutation.
  def transform(css, &block)
    doc = Nokogiri::HTML.fragment(@html)
    doc.css(css).each(&block)
    @html = doc.to_html

    self
  end

  def decorate_image(img)
    src = img.attr("src")
    normalize_image_src(img, src)

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
end
