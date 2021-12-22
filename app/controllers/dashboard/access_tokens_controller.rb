# frozen_string_literal: true

class Dashboard::AccessTokensController < Dashboard::BaseController
  def index
    @pagy, @access_tokens = pagy current_user.access_tokens.order(created_at: :desc)
  end

  def create
    @access_token = current_user.access_tokens.create access_token_params
  end

  def destroy
    @access_token = current_user.access_tokens.find(params[:id])
    @access_token.destroy
  end

  private

  def access_token_params
    params.require(:access_token).permit(:memo)
  end
end
