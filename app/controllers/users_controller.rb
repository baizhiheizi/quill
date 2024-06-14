# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :load_user

  def show
    @tab = params[:tab] || 'published'

    @page_title = @user&.name
    @page_description = @user&.bio
    @page_image = @user&.avatar

    impressionist @user
  end

  def share
    impressionist @user, 'share'
  end

  private

  def load_user
    uid = params[:uid] || params[:user_id] || params[:full_user_uid] || request.subdomain
    @user = User.fetch_by_uniq_keys(uid:)
    redirect_back fallback_location: root_path if @user.blank?
  end
end
