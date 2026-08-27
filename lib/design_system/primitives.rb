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
  # In Phase A the registry is hand-populated; in Phase A completion it is
  # populated from a directory scan of app/views/shared/_*.html.erb.
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
        # UiHelper helper name (if one exists).
        helper_map = {
          "_button.html.erb"            => :render_button,
          "_chip.html.erb"              => :render_chip,
          "_list_row.html.erb"          => :render_list_row,
          "_value_note.html.erb"        => :render_value_note,
          "_notification_card.html.erb" => :render_notification_card,
          "_skeleton.html.erb"          => :render_skeleton,
          "_state_empty.html.erb"       => :render_state_empty,
          "_table.html.erb"             => :render_table,
          "_ui_card.html.erb"           => :ui_card,
          "_ui_input.html.erb"          => :ui_input,
          "_modal.html.erb"             => :render_modal,
          "_dropdown.html.erb"          => :render_dropdown
        }

        dir = Rails.root.join("app/views/shared").to_s
        Dir.glob(File.join(dir, "_*.html.erb"))
           .sort
           .map do |path|
             file = File.basename(path, ".html.erb") # strip the suffix only
             { name: file.sub(/^_/, "").to_sym, partial_path: path.sub(Rails.root.to_s + "/", ""), helper: helper_map["#{file}.html.erb"] }
           end
      end
    end
  end
end
