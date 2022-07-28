# frozen_string_literal: true

class LocalesController < ApplicationController
  def create
    session[:current_locale] = params[:locale] if params[:locale]&.to_sym.in? I18n.available_locales
    redirect_to(params[:return_to].presence || root_path)
  end
end
