# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    redirect_to articles_path
  end
end
