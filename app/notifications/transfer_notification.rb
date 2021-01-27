# frozen_string_literal: true

class TransferNotification < Noticed::Base
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'APP_CARD'

  param :transfer

  def transfer_type
    case params[:transfer].transfer_type.to_sym
    when :author_revenue
      t('.author_revenue')
    when :reader_revenue
      t('.reader_revenue')
    when :payment_refund
      t('.payment_refund')
    when :bonus
      t('.bonus')
    end
  end

  def data
    {
      icon_url: params[:transfer].token[:icon_url],
      title: params[:transfer].amount.to_f.round(8).to_s,
      description: params[:transfer].token[:symbol],
      action: "mixin://snapshots?trace=#{params[:transfer].trace_id}"
    }
  end

  def message
    [t('.received'), params[:transfer].price_tag, transfer_type].join(' ')
  end

  def url
    format(
      '%<host>s/snapshots/%<snapshot_id>s',
      host: 'https://mixin.one',
      snapshot_id: params[:transfer].snapshot_id
    )
  end
end
