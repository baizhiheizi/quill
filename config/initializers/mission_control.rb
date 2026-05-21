# frozen_string_literal: true

Rails.application.configure do
  config.mission_control.jobs.base_controller_class = "Admin::BaseController"
  config.mission_control.jobs.http_basic_auth_enabled = false
end
