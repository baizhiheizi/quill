# frozen_string_literal: true

module Articles::PosterGenerator
  extend ActiveSupport::Concern

  def thumb_url
    @thumb_url ||= resolve_thumb_url
  end

  def cover_url
    [ Settings.storage.endpoint, cover.key ].join("/") if cover.attached?
  end

  def poster_url
    if poster.attached?
      [ Settings.storage.endpoint, poster.key ].join("/")
    else
      generate_poster_async
      nil
    end
  end

  def generated_poster_url
    grover_article_poster_url uuid, token: Rails.application.credentials.dig(:grover, :token), format: :png
  end

  def generate_poster
    file = URI.parse(generated_poster_url).open
    poster.attach io: file, filename: "#{title}_poster"
  end

  def generate_poster_async
    Articles::GeneratePosterJob.perform_later id
  end

  def qrcode_base64
    [ "data:image/png;base64, ",
     Base64.encode64(
       RQRCode::QRCode.new(
         user_article_url(author, self)
       ).as_png(border_modules: 0).to_s
     ) ].join
  end

  private

  def resolve_thumb_url
    return cover_url if cover.attached?

    extract_content_image_url if free?
  end

  def extract_content_image_url
    Nokogiri::HTML
      .fragment(content_as_html)
      .css("img")
      .map(&->(img) { img.attr("src") })
      .find(&->(url) { URI::DEFAULT_PARSER.make_regexp.match?(url) })
  end
end
