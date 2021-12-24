# frozen_string_literal: true

class Users::BaseController < ApplicationController
  before_action :load_user!

  private

  def load_user!
    @user = User.find_by uid: params[:user_uid]
    redirect_to root_path if @user.blank?
  end
end
