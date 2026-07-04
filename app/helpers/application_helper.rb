# frozen_string_literal: true

module ApplicationHelper
  include UiHelper

  # Renders an external image URL without passing bare strings to Propshaft.
  def remote_image_tag(source, options = {})
    return if source.blank?

    source = source.to_s
    return unless source.start_with?("http://", "https://", "//", "/")

    options = options.symbolize_keys
    options[:loading] = "lazy" if options.delete(:lazy)
    image_tag(source, **options)
  end

  def article_card_image_url(article)
    return article.cover_url if article.cover.attached?

    article.thumb_url if article.free?
  end
end
