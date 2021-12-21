# frozen_string_literal: true

class SubscribeUsersController < ApplicationController
  before_action :authenticate_user!
  before_action :load_user

  def create
    return if current_user == @user

    current_user.create_action :subscribe, target: @user
  end

  def destroy
    return if current_user == @user

    current_user.destroy_action :subscribe, target: @user
  end

  private

  def load_user
    @user = User.find_by uid: params[:uid]
  end
end
