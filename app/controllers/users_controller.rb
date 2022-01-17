# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :load_user
  before_action :authenticate_user!, only: %i[block unblock]

  def show
    @tab = params[:tab] || 'published'

    @page_title = @user&.name
    @page_description = @user&.bio
    @page_image = @user&.avatar
  end

  def block
    return if @user.blank?

    current_user.create_action :block, target: @user
  end

  def unblock
    return if @user.blank?

    current_user.destroy_action :block, target: @user
  end

  private

  def load_user
    @user = User.find_by uid: params[:uid] || params[:user_uid]
  end
end
