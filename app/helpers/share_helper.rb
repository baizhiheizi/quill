# frozen_string_literal: true

module ShareHelper
  def share_to_twitter(url, text, via = Settings.twitter_account)
    [
      "https://twitter.com/intent/tweet?",
      "text=",
      ERB::Util.url_encode(text),
      "&url=",
      ERB::Util.url_encode(url),
      "&via=",
      ERB::Util.url_encode(via)
    ].join
  end

  def share_to_telegram(url, text)
    [
      "https://t.me/share/url?url=",
      ERB::Util.url_encode(url),
      "&text=",
      ERB::Util.url_encode(text)
    ].join
  end

  def share_to_mixin(url, title:, description:, icon_url:)
    data = {
      action: url,
      app_id: QuillBot.api.client_id,
      title: title.truncate(36),
      description: description.truncate(128),
      icon_url:
    }

    [
      "mixin://send?category=app_card&data=",
      ERB::Util.url_encode(Base64.strict_encode64(data.to_json))
    ].join
  end
end
