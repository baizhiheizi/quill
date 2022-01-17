# frozen_string_literal: true

class Dashboard::BlockUsersController < Dashboard::BaseController
  def index
    @pagy, @users = pagy current_user.block_users.order('actions.created_at DESC')
  end

  def create
    current_user.create_action :block, target: @user
  end

  def destroy
    current_user.destroy_action :block, target: @user
  end

  private

  def load_user
    @user = User.find_by uid: params[:uid]
  end
end
