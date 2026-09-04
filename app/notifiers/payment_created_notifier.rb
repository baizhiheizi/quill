# frozen_string_literal: true

class PaymentCreatedNotifier < ApplicationNotifier
  notifies :payment_created

  required_param :payment

  notification_methods do
    def message
      [ t(".paid"), params[:payment].price_tag ].join(" ")
    end

    def url
      format(
        "%<host>s/snapshots/%<snapshot_id>s",
        host: "https://mixin.one",
        snapshot_id: params[:payment].snapshot_id
      )
    end
  end
end
