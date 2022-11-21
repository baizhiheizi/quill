# frozen_string_literal: true

class Users::BaseController < ApplicationController
  before_action :load_user!, :set_page_meta

  private

  def load_user!
    @user =
      if request.subdomain.present?
        User.fetch_by_uniq_keys subdomain: request.subdomain.strip
      else
        User.fetch_by_uniq_keys uid: params[:user_uid]
      end

    redirect_to root_url(subdomain: ''), allow_other_host: true if @user.blank?
  end

  def set_page_meta
    @page_title = @user.name
    @page_description = @user.bio
    @page_image = @user.avatar
  end
end
