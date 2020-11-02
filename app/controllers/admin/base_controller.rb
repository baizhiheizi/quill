# frozen_string_literal: true

class Admin::BaseController < ActionController::Base
  layout 'admin'

  helper_method :base_props

  private

  def base_props
    {
      current_admin: current_admin&.as_json(only: %i[name]),
      prsdigg: {
        app_id: MixinBot.api.client_id
      }
    }
  end
end
