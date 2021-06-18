# frozen_string_literal: true

class LandingController < ApplicationController
  skip_before_action :ensure_launched!

  layout 'landing'

  def index
    if launched?
      redirect_to root_path
    else
      @launch_time = Time.zone.parse(Settings.launch_time).strftime('%Y-%m-%d %H:%M:%S')
    end
  end
end
