# frozen_string_literal: true

class UsersController < ApplicationController
  def show
    @tab = params[:tab] || 'published'
    @user = User.find_by uid: params[:uid]
  end
end
