# frozen_string_literal: true

# Use this hook to configure impressionist parameters
# Impressionist.setup do |config|
# Define ORM. Could be :active_record (default), :mongo_mapper or :mongoid
# config.orm = :active_record
# end

# impressionist's engine hooks ActionController before ImpressionistController is
# autoloaded when middleware gems change boot order (e.g. omniauth).
Rails.application.config.before_initialize do
  gem_path = Gem.loaded_specs["impressionist"]&.full_gem_path
  require File.join(gem_path, "app/controllers/impressionist_controller.rb") if gem_path
end
