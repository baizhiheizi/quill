# frozen_string_literal: true

module ShareHelper
  def share_to_twitter(url, text, via = 'prsdigg')
    [
      'https://twitter.com/intent/tweet?',
      'text=',
      text,
      '&url=',
      url,
      '&via=',
      via
    ].join
  end

  def share_to_facebook(url)
    [
      'https://facebook.com/sharer/sharer.php?u=',
      url
    ].join
  end

  def share_to_mixin(url, title:, description:, icon_url:)
    data = {
      action: url,
      app_id: PrsdiggBot.api.client_id,
      title: title.truncate(36),
      description: description.truncate(128),
      icon_url: icon_url
    }

    [
      'mixin://send?category=app_card&data=',
      Base64.encode64(data.to_json)
    ].join
  end
end
