# frozen_string_literal: true

class CurrenciesController < ApplicationController
  def index
    @currencies =
      if params[:type] == 'swappable'
        Currency.swappable
      else
        Currency.pricable
      end
  end
end
