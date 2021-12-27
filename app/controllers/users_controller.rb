# frozen_string_literal: true

class UsersController < ApplicationController
  def show
    @tab = params[:tab] || 'published'
    @user = User.find_by uid: params[:uid]

    @page_title = @user.name
    @page_description = @user.bio
    @page_image = @user.avatar
  end
end
