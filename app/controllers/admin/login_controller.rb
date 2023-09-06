# frozen_string_literal: true

class Admin::LoginController < Admin::BaseController
  skip_before_action :authenticate_admin!, only: %i[new create]
  layout false

  def new
  end

  def create
    admin = Administrator.find_by(name: params[:name])
    admin_sign_in(admin) if admin&.authenticate(params[:password])
    redirect_to admin_root_path
  end

  def delete
    admin_sign_out
    redirect_to admin_root_path
  end
end
