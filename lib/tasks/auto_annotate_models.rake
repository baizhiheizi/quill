# frozen_string_literal: true

# NOTE: only doing this in development as some production environments (Heroku)
# NOTE: are sensitive to local FS writes, and besides -- it's just not proper
# NOTE: to have a dev-mode tool do its thing in production.
if Rails.env.development?
  begin
    require "annotaterb"
  rescue LoadError
    # annotaterb is only in the development group
  else
    # The set_annotation_options task reads .annotaterb.yml and layers any
    # matching ENV-var overrides on top, so developers can tweak behavior
    # per-shell without editing the committed config file.
    task set_annotation_options: :environment do
      base_config = AnnotateRb::ConfigLoader.load_config
      env_overrides = build_env_overrides(base_config)
      merged = base_config.merge(env_overrides)

      AnnotateRb::Runner.run([ "models", *env_overrides_argv(env_overrides) ])
    end

    AnnotateRb::Core.load_rake_tasks
  end
end

# Reads ENV and returns a hash of overrides for any key that:
#   1. has a matching ENV variable set (e.g. ENV["force"] for config key :force)
#   2. exists as a key in `base_config` (so we don't accidentally inject garbage)
#
# The returned hash should use the SAME keys (symbols) as base_config, and the
# values should be coerced from String to the type that base_config expects
# (Boolean for "true"/"false", Integer for numeric options, Array for
# comma-separated lists, etc.).
def build_env_overrides(base_config)
  # TODO: implement env-var override extraction with type coercion
  {}
end

# Turns the env-overrides hash into CLI-style args so AnnotateRb::Runner.run
# sees them at the same precedence as command-line flags (which override YAML).
def env_overrides_argv(overrides)
  overrides.flat_map { |key, value| [ "--#{key}", value.to_s ] }
end
