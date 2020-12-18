# frozen_string_literal: true

class Dashboard::BaseController < ApplicationController
  layout 'dashboard'

  before_action :authenticate_user!
end
