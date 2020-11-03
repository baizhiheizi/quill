# frozen_string_literal: true

class Admin::SessionsController < Admin::BaseController
  def delete
    admin_sign_out
    redirect_to admin_root_path
  end
end
