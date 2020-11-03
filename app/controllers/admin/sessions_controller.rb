# frozen_string_literal: true

class Admin::SessionsController < Admin::BaseController
  skip_before_action :verify_authenticity_token, only: :create
  def delete
    admin_sign_out

    redirect_to admin_root_path
  end
end
