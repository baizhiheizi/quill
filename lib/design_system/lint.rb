# frozen_string_literal: true

require "set"

module DesignSystem
  # Static analyzer for the design-system contracts.
  #
  # Usage:
  #   DesignSystem::Lint.run(Rails.root)               # full check (CI mode)
  #   DesignSystem::Lint.run(Rails.root, phase: :a)    # phase-scoped check
  #
  # Returns: Array<DesignSystem::Violation>
  #
  # Phase model (matches `bin/lint-design-system --phase`):
  #   :a - design-system foundation (token layer + new partials + lint rules)
  #   :b - public surfaces
  #   :c - authoring surfaces (dashboard + editor)
  #   :d - admin + API + errors + notifications
  #
  # During phased development, each phase gates on the previous phase being
  # clean (zero violations).
  class Lint
    class PhaseError < StandardError; end

    # File-level allowlist. Each entry: relative path (String) => reason (String).
    # Reasons are committed next to the path so future maintainers know why
    # an exception is allowed.
    ALLOWLIST = {
      "app/views/articles/_card_cover.html.erb" => "procedural cover-art SVG (not an icon)",
      "app/javascript/utils/notify.js" => "toast icons migrated to i-[tabler--*]; allowlist shrinks in Phase 7",
      "app/assets/stylesheets/application.tailwind.css" => "source of token layer (hex literals are intentional)",
      "app/assets/stylesheets/lexxy_overrides.css" => "Lexxy editor internals; not owned by Quill"
    }.freeze

    HEX_RE = /(?<![0-9A-Za-z_])#[0-9A-Fa-f]{3,8}\b/.freeze

    # Files where the scan walks: ERB views, JS controllers/helpers, ERB helpers, CSS.
    SCAN_GLOBS = [
      "app/views/**/*.erb",
      "app/javascript/**/*.js",
      "app/helpers/**/*.rb",
      "app/assets/stylesheets/**/*.css"
    ].freeze

    # Files/dirs to skip entirely.
    IGNORE_DIRS = %w[
      node_modules
      .git
      tmp
      log
      coverage
      app/assets/builds
      docs/superpowers/specs/opendesign-011
    ].freeze

    def self.run(root_path, phase: nil)
      raise PhaseError, "Unknown phase: #{phase.inspect}" if phase && !%i[a b c d].include?(phase.to_sym)

      instance = self.new
      instance.root_path = root_path
      instance.phase = phase&.to_sym
      instance.violations = []
      instance.send(:files).each { |path| instance.send(:scan_file, path) }
      instance.violations
    end

    attr_accessor :root_path, :phase, :violations

    def initialize
      # Default accessors set in .run
    end

    private

    def root
      Pathname.new(root_path)
    end

    def files
      pattern = "{#{SCAN_GLOBS.join(",")}}"
      results = Dir.glob(root.join(pattern))
      results.reject { |f| ignored?(f) }
    end

    def ignored?(path)
      rel = path.sub(root.to_s + "/", "")
      IGNORE_DIRS.any? { |dir| rel.start_with?(dir + "/") || rel == dir }
    end

    def allowlisted?(path)
      rel = path.sub(root.to_s + "/", "")
      ALLOWLIST.key?(rel)
    end

    def scan_file(path)
      return if allowlisted?(path)

      lines = File.readlines(path, encoding: "UTF-8", invalid: :replace, undef: :replace)
      rel = path.sub(root.to_s + "/", "")

      lines.each_with_index do |line, i|
        check_hex!(rel, line, i + 1)
        check_svg_icon!(rel, line, i + 1)
        check_tag_style!(rel, line, i + 1)
        check_reward_bg!(rel, line, i + 1)
        check_button_class!(rel, line, i + 1)
        check_chip_class!(rel, line, i + 1)
        check_raw_table!(rel, line, i + 1)
        check_raw_border_radius!(rel, line, i + 1)
        check_font_display_conflict!(rel, line, i + 1)
        check_tabler_slug!(rel, line, i + 1)
        check_raw_input!(rel, line, i + 1)
        check_raw_modal!(rel, line, i + 1)
        check_raw_dropdown!(rel, line, i + 1)
      end
    end

    # DS001 — raw hex outside the token layer / coin allowlist.
    def check_hex!(rel, line, ln)
      return if rel == "app/views/layouts/application.html.erb" && line.include?("theme-color")
      return if rel == "app/views/layouts/public.html.erb" && line.include?("theme-color")
      return if rel == "app/views/layouts/editor.html.erb" && line.include?("theme-color")
      return if rel == "app/views/layouts/homepage.html.erb" && line.include?("theme-color")
      return if rel == "app/javascript/controllers/darkmode_controller.js" && line.include?("setAttribute")
      return if rel == "app/assets/stylesheets/application.tailwind.css"

      # Skip comments / strings that are obviously a Tabler icon class.
      stripped = line.sub(%r{//.*}, "").sub(%r{#.*}, "")

      HEX_RE.match(stripped) do |match|
        violations << Violation.new(
          rule_id: "DS001",
          severity: :error,
          file: rel,
          line: ln,
          message: "raw hex color `#{match[0]}` outside the token layer; use `bg-*` / `text-*` / `border-*` utilities or extend the token layer",
        )
      end
    end

    # DS002 — hand-rolled <svg> in views (outside the allowlist).
    def check_svg_icon!(rel, line, ln)
      return unless rel.start_with?("app/views/")
      return if line.include?("i-[tabler--")
      return unless line.include?("<svg ")

      # Procedural cover-art generator draws circles/ellipses/rects, not icons.
      return if rel == "app/views/articles/_card_cover.html.erb"

      violations << Violation.new(
        rule_id: "DS002",
        severity: :error,
        file: rel,
        line: ln,
        message: "hand-rolled <svg> in a view; use `i-[tabler--*]` (or another documented icon utility) instead",
      )
    end

    # DS003 — `tag-style-0`..`tag-style-5` remnants.
    def check_tag_style!(rel, line, ln)
      return unless line.match?(/\btag-style-[0-5]\b/)

      violations << Violation.new(
        rule_id: "DS003",
        severity: :error,
        file: rel,
        line: ln,
        message: "`tag-style-*` is deprecated; use `<%= render_chip …, kind: :topic %>`",
      )
    end

    # DS004 — `bg-reward` / `border-reward` (reward is text-only).
    def check_reward_bg!(rel, line, ln)
      return unless line.match?(/\b(bg|border)-reward\b/)

      violations << Violation.new(
        rule_id: "DS004",
        severity: :error,
        file: rel,
        line: ln,
        message: "reward tint is text-only; use `text-reward` (or `render_value_note`) — never `bg-reward` or `border-reward`",
      )
    end

    # DS005 — raw `<button class="btn btn-primary">` outside `shared/_button.html.erb`.
    def check_button_class!(rel, line, ln)
      return unless rel.start_with?("app/views/")
      return if rel == "app/views/shared/_button.html.erb"
      return if rel == "app/views/design_system/_buttons.html.erb"
      return if line.include?("render_button")
      return unless line.match?(/\bbtn\s+btn-(primary|secondary|soft|ghost|danger)\b/)

      violations << Violation.new(
        rule_id: "DS005",
        severity: :error,
        file: rel,
        line: ln,
        message: "raw `.btn .btn-*` outside `shared/_button.html.erb`; use `<%= render_button … %>`",
      )
    end

    # DS006 — raw `<span class="chip chip-*">` outside `shared/_chip.html.erb`.
    def check_chip_class!(rel, line, ln)
      return unless rel.start_with?("app/views/")
      return if rel == "app/views/shared/_chip.html.erb"
      return if rel == "app/views/design_system/_chips.html.erb"
      return if line.include?("render_chip")
      return unless line.match?(/\bchip\s+chip-[a-z-]+/i)

      violations << Violation.new(
        rule_id: "DS006",
        severity: :error,
        file: rel,
        line: ln,
        message: "raw `.chip .chip-*` outside `shared/_chip.html.erb`; use `<%= render_chip … %>`",
      )
    end

    # DS007 — raw `<table>` outside `shared/_table.html.erb`.
    def check_raw_table!(rel, line, ln)
      return unless rel.start_with?("app/views/")
      return if rel == "app/views/shared/_table.html.erb"
      return if rel == "app/views/design_system/_table.html.erb"
      return unless line.include?("<table")

      violations << Violation.new(
        rule_id: "DS007",
        severity: :warning,
        file: rel,
        line: ln,
        message: "raw `<table>` outside `shared/_table.html.erb`; use `<%= render_table … %>`",
      )
    end

    # DS008 — literal `border-radius:` outside `:root`.
    def check_raw_border_radius!(rel, line, ln)
      return unless rel.start_with?("app/assets/stylesheets/")
      return if rel == "app/assets/stylesheets/application.tailwind.css"
      return unless line.match?(/border-radius:\s*\d/)

      violations << Violation.new(
        rule_id: "DS008",
        severity: :warning,
        file: rel,
        line: ln,
        message: "literal `border-radius:` outside `:root`; use one of `--radius`, `--radius-lg`, `--radius-full`",
      )
    end

    # DS009 — font-display + muted-color semantic conflict.
    def check_font_display_conflict!(rel, line, ln)
      return unless rel.start_with?("app/views/")
      return unless line.include?("font-display") && (line.include?("text-base-content/60") || line.include?("text-muted"))

      violations << Violation.new(
        rule_id: "DS009",
        severity: :warning,
        file: rel,
        line: ln,
        message: "`font-display` with muted chrome color — use `font-mono` or remove `text-base-content/60`",
      )
    end

    # DS010 — new tabler slug (informational).
    TABLER_SLUGS_SEEN = Set.new
    def check_tabler_slug!(rel, line, ln)
      return unless rel.start_with?("app/views/")

      line.scan(/i-\[tabler--([a-z0-9-]+)\]/i).flatten.uniq.each do |slug|
        next if TABLER_SLUGS_SEEN.include?(slug)
        TABLER_SLUGS_SEEN << slug
        violations << Violation.new(
          rule_id: "DS010",
          severity: :info,
          file: rel,
          line: ln,
          message: "new tabler slug `#{slug}`; ensure `@iconify-json/tabler` ships this icon",
        )
      end
    end

    # DS011 — raw `<input class="input">` outside `shared/_ui_input.html.erb`.
    def check_raw_input!(rel, line, ln)
      return unless rel.start_with?("app/views/")
      return if rel == "app/views/shared/_ui_input.html.erb"
      return if rel == "app/views/design_system/_forms.html.erb"
      return if line.include?("ui_input")
      return unless line.include?("<input ") && line.match?(/\bclass\s*=\s*["'][^"']*\binput\b/i)

      violations << Violation.new(
        rule_id: "DS011",
        severity: :error,
        file: rel,
        line: ln,
        message: "raw `<input class=\"input\">` outside `shared/_ui_input.html.erb`; use `<%= ui_input … %>`",
      )
    end

    # DS012 — raw modal markup outside `shared/_modal.html.erb`.
    def check_raw_modal!(rel, line, ln)
      return unless rel.start_with?("app/views/")
      return if rel == "app/views/shared/_modal.html.erb"
      return if rel == "app/views/design_system/_modal.html.erb"
      return if line.include?("render_modal")
      return unless line.include?("<div ") && line.match?(/\bclass\s*=\s*["'][^"']*\bmodal\b/i)

      violations << Violation.new(
        rule_id: "DS012",
        severity: :error,
        file: rel,
        line: ln,
        message: "raw `.modal` markup outside `shared/_modal.html.erb`; use `<%= render_modal … %>`",
      )
    end

    # DS013 — raw dropdown markup outside `shared/_dropdown.html.erb`.
    def check_raw_dropdown!(rel, line, ln)
      return unless rel.start_with?("app/views/")
      return if rel == "app/views/shared/_dropdown.html.erb"
      return if rel == "app/views/design_system/_dropdown.html.erb"
      return if line.include?("render_dropdown")
      return unless line.include?("<div ") && line.match?(/\bclass\s*=\s*["'][^"']*\bdropdown\b/i)

      violations << Violation.new(
        rule_id: "DS013",
        severity: :error,
        file: rel,
        line: ln,
        message: "raw `.dropdown` markup outside `shared/_dropdown.html.erb`; use `<%= render_dropdown … %>`",
      )
    end
  end
end
