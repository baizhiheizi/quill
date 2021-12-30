# frozen_string_literal: true

class HealthzController < ApplicationController
  skip_before_action :ensure_launched!

  def index
    render json: {}, status: :ok
  end
end
