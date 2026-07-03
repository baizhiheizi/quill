# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :load_user
  layout "public", only: :show

  def show
    @tab = params[:tab] || "published"

    @page_title = @user&.name
    @page_description = @user&.bio
    @page_image = @user&.avatar

    impressionist @user
  end

  def share
    impressionist @user, "share"
  end

  private

  def load_user
    uid = params[:uid] || params[:user_id] || params[:full_user_uid] || request.subdomain
    @user = User.find_by(uid:)
    render_not_found_page if @user.blank?
  end
end
