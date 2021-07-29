# frozen_string_literal: true

set :stages, %w[main ja]
set :default_stage, 'ja'

require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'
require 'mina/logs'
require 'mina/multistage'

%w[puma blaze sidekiq sidekiq-2].each do |job|
  namespace job.to_sym do
    task :start do
      command %(echo "-----> exec: sudo systemctl start #{job}")
      command %(sudo systemctl start puma)
    end

    task :stop do
      command %(echo "-----> exec: sudo systemctl stop #{job}")
      command %(sudo systemctl stop #{job})
    end

    task :restart do
      command %(echo "-----> exec: sudo systemctl restart #{job}")
      command %(sudo systemctl restart #{job})
    end

    task :reload do
      command %(echo "-----> exec: sudo systemctl reload #{job}")
      command %(sudo systemctl reload #{job})
    end

    task :log do
      command %(echo "-----> exec: journalctl -f -u #{job}")
      command %(journalctl -f -u #{job})
    end
  end
end

set :shared_dirs, fetch(:shared_dirs, []).push('log', 'public/uploads', 'node_modules', 'storage')
set :shared_files, fetch(:shared_files, []).push('config/database.yml')
set :shared_files, fetch(:shared_files, []).push('config/settings.yml')
set :shared_files, fetch(:shared_files, []).push('config/master.key')

set :puma_config, -> { "#{fetch(:current_path)}/config/puma.rb" }

task :remote_environment do
  invoke :'rbenv:load'
end

task :setup do
  command %(mkdir -p "#{fetch(:shared_path)}/tmp/sockets")
  command %(chmod g+rx,u+rwx "#{fetch(:shared_path)}/tmp/sockets")

  command %(mkdir -p "#{fetch(:shared_path)}/tmp/pids")
  command %(chmod g+rx,u+rwx "#{fetch(:shared_path)}/tmp/pids")

  command %(mkdir -p "#{fetch(:shared_path)}/log")
  command %(chmod g+rx,u+rwx "#{fetch(:shared_path)}/log")

  command %(mkdir -p "#{fetch(:shared_path)}/public/uploads")
  command %(chmod g+rx,u+rwx "#{fetch(:shared_path)}/public/uploads")

  command %(mkdir -p "#{fetch(:shared_path)}/node_modules")
  command %(chmod g+rx,u+rwx "#{fetch(:shared_path)}/node_modules")

  command %(mkdir -p "#{fetch(:shared_path)}/storage")
  command %(chmod g+rx,u+rwx "#{fetch(:shared_path)}/storage")

  command %(mkdir -p "#{fetch(:shared_path)}/config")
  command %(chmod g+rx,u+rwx "#{fetch(:shared_path)}/config")

  command %(touch "#{fetch(:shared_path)}/config/database.yml")
  command %(echo "-----> Be sure to edit '#{fetch(:shared_path)}/config/database.yml'")

  command %(touch "#{fetch(:shared_path)}/config/settings.yml")
  command %(echo "-----> Be sure to edit '#{fetch(:shared_path)}/config/settings.yml'")

  command %(touch "#{fetch(:shared_path)}/config/master.key")
  command %(echo "-----> Be sure to edit '#{fetch(:shared_path)}/config/master.key'")
end

desc 'link credentials file to for current stage'
task :link_credentials_file do
  command %(echo "-----> exec: cp ./config/credentials/#{fetch(:stage)}.yml.enc ./config/credentials.yml.enc")
  command %(cp "./config/credentials/#{fetch(:stage)}.yml.enc" "./config/credentials.yml.enc")
end

desc 'generate translation.json'
task :rake_react_on_rails_locale do
  command %(echo "-----> exec: bin/rake react_on_rails:locale")
  command %(#{fetch(:rake)} react_on_rails:locale)
end

desc 'Deploys the current version to the server.'
task :deploy do
  command %(echo "-----> Server: #{fetch(:domain)}")
  command %(echo "-----> Path: #{fetch(:deploy_to)}")
  command %(echo "-----> Branch: #{fetch(:branch)}")

  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :link_credentials_file
    invoke :'sidekiq:reload'
    invoke :'sidekiq-2:reload'
    invoke :'bundle:install'
    # invoke :rake_react_on_rails_locale
    # invoke :'rails:assets_precompile'
    invoke :'rails:db_migrate'
    invoke :'deploy:cleanup'

    on :launch do
      invoke :'rbenv:load'
      invoke :'puma:restart'
      invoke :'sidekiq:restart'
      invoke :'sidekiq-2:restart'
      invoke :'blaze:restart'
    end
  end
end

desc 'Prepare the first deploy on server.'
task :first_deploy do
  command %(echo "-----> Server: #{fetch(:domain)}")
  command %(echo "-----> Path: #{fetch(:deploy_to)}")
  command %(echo "-----> Branch: #{fetch(:branch)}")

  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :link_credentials_file
    invoke :'bundle:install'
    invoke :'deploy:cleanup'

    on :launch do
      invoke :'rbenv:load'
      invoke :'rails:db_create'
      invoke :'rails:db_migrate'
    end
  end
end
