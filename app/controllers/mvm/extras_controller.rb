# frozen_string_literal: true

class MVM::ExtrasController < MVM::BaseController
  def create
    res = MVM.api.extra receivers: params[:receivers], threshold: params[:threshold], extra: params[:extra]

    render json: res
  end
end
