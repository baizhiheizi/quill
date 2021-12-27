# frozen_string_literal: true

class Users::BaseController < ApplicationController
  before_action :load_user!, :set_page_meta

  private

  def load_user!
    @user = User.find_by uid: params[:user_uid]
    redirect_to root_path if @user.blank?
  end

  def set_page_meta
    @page_title = @user.name
    @page_description = @user.bio
    @page_image = @user.avatar
  end
end
