# frozen_string_literal: true

module DesignSystem
  # Registry of every design-system primitive.
  #
  # A "primitive" is one ERB partial under app/views/shared/ that every
  # consumer in the app funnels through (button, chip, list row, modal, etc.).
  # The registry is the single source-of-truth for:
  #   - the design-system reference page (DesignSystemController#show renders
  #     one example per registered primitive)
  #   - the lint allowlist (DS005/DS006/DS011/DS012/DS013 skip the partial
  #     itself)
  #
  # The registry is populated from a directory scan of
  # app/views/shared/_*.html.erb, and each partial is paired with its
  # UiHelper wrapper by naming convention — so neither the filesystem nor
  # the helper module can drift from the registry without a test failing.
  module Primitives
    class Registry
      def self.all
        @all ||= default_prims
      end

      def self.reset!
        @all = nil
      end

      def self.register(name, partial_path:, helper: nil, controller: nil)
        all << {
          name: name.to_sym,
          partial_path: partial_path,
          helper: helper,
          controller: controller
        }
      end

      def self.default_prims
        # T080: derive the canonical primitive list from a directory scan of
        # app/views/shared/_*.html.erb so the registry and the filesystem
        # never drift. Each entry pairs the partial with its corresponding
        # UiHelper wrapper, derived by convention rather than maintained by
        # hand (see .helper_for) — a helper with no partial, or a partial with
        # a wrapper the registry missed, is a registry-contract test failure.
        dir = Rails.root.join("app/views/shared").to_s
        Dir.glob(File.join(dir, "_*.html.erb"))
           .sort
           .map do |path|
             file = File.basename(path, ".html.erb") # strip the suffix only
             name = file.sub(/^_/, "")
             { name: name.to_sym, partial_path: path.sub(Rails.root.to_s + "/", ""), helper: helper_for(name) }
           end
      end

      # Convention: partial `shared/_x.html.erb` is wrapped by
      # `UiHelper#render_x`, or by `UiHelper#x` for the two legacy
      # form-builder helpers (`ui_card`, `ui_input`).
      def self.helper_for(name)
        candidates = [:"render_#{name}", name.to_sym]
        (primitive_helpers & candidates).first
      end

      def self.primitive_helpers
        UiHelper.instance_methods(false)
      rescue NameError
        # `UiHelper` is autoloaded; it is always loadable in a booted Rails app,
        # but keep the registry usable if it is required outside one.
        []
      end
    end
  end
end
