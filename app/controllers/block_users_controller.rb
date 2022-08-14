# frozen_string_literal: true

class BlockUsersController < ApplicationController
  before_action :authenticate_user!
  before_action :load_user

  def new
  end

  def create
    return if current_user == @user

    Action.transaction do
      current_user.create_action :block, target: @user
      current_user.destroy_action :subscribe, target: @user
      @user.destroy_action :subscribe, target: current_user
    end
  end

  def destroy
    return if current_user == @user

    current_user.destroy_action :block, target: @user
  end

  private

  def load_user
    @user = User.find_by uid: params[:uid]
  end
end
