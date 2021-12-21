# frozen_string_literal: true

class Dashboard::SubscribeUsersController < Dashboard::BaseController
  def index
    @users = current_user.subscribe_users
  end

  def create
    current_user.create_action :subscribe, target: @user
  end

  def destroy
    current_user.destroy_action :subscribe, target: @user
  end

  private

  def load_user
    @user = User.find_by uid: params[:uid]
  end
end
