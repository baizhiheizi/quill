# frozen_string_literal: true

class PaymentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @article = Article.find_by uuid: params[:uuid]
    @currency = Currency.find_or_create_by asset_id: params[:asset_id]
    return if @article.blank? || @currency.blank?
  end
end
