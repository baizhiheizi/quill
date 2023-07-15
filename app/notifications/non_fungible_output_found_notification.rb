# frozen_string_literal: true

class NonFungibleOutputFoundNotification < ApplicationNotification
  deliver_by :database, if: :collectible_valid?
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'APP_CARD', if: :may_notify_via_mixin_bot?

  param :non_fungible_output

  def non_fungible_output
    params[:non_fungible_output]
  end

  def data
    {
      icon_url: icon_url,
      title: title.truncate(36),
      description: message.truncate(72),
      action: url,
      shareable: false
    }
  end

  def message
    [t('.found'), title].join(' ')
  end

  def title
    [non_fungible_output.collectible&.collection&.name, "(##{non_fungible_output.collectible&.identifier})"].join(' ')
  end

  def icon_url
    non_fungible_output.collectible&.media_url
  end

  def url
    non_fungible_output.collectible&.trident_url
  end

  def collectible_valid?
    non_fungible_output.state == 'unspent' && non_fungible_output.collectible&.collection.present?
  end

  def may_notify_via_mixin_bot?
    collectible_valid? && recipient_messenger?
  end
end
