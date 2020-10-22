# frozen_string_literal: true

if ENV['RAILS_ENV'] == 'production'
  app_root = '/data/www/prsdigg/shared'
  pidfile "#{app_root}/tmp/pids/puma.pid"
  state_path "#{app_root}/tmp/pids/puma.state"
  bind "unix://#{app_root}/tmp/sockets/puma.sock"
  activate_control_app "unix://#{app_root}/tmp/sockets/pumactl.sock"
  workers 2
  threads 8, 16
  nakayoshi_fork
  prune_bundler

  stdout_redirect "#{app_root}/log/puma_access.log", "#{app_root}/log/puma_error.log", true
else
  plugin :tmp_restart
end
