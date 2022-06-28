# frozen_string_literal: true

class CurrenciesController < ApplicationController
  def index
    @currencies = Currency.swappable
  end
end
