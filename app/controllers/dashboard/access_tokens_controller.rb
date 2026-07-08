# frozen_string_literal: true

class Dashboard::AccessTokensController < Dashboard::BaseController
  def index
    @pagy, @access_tokens = pagy current_user.access_tokens.order(created_at: :desc)
  end

  def create
    @access_token = current_user.access_tokens.new access_token_params

    return if @access_token.save

    # Validation failed (e.g. per-user token cap reached). Re-show the form
    # with the errors inside the modal slot.
    render :create, status: :unprocessable_entity
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
