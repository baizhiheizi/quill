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

    # ─── Rule-scoped legacy debt ───────────────────────────────────────────
    # The reasons below describe the raw-markup backlog that predates the
    # design system (issue #2077). Each file is exempted from the specific
    # rules it trips and nothing else, so a new rule or a new file stays
    # policed. Deleting an entry is the fix.
    LEGACY_ADMIN_TABLE = "admin index table renders a collection of row partials inside <tbody>; _table.html.erb has no row-partial slot to receive it yet"
    LEGACY_ADMIN_BUTTONS = "admin console markup predates the primitive: row-action link_to and query-bar form.submit carry .btn classes; converting needs a submit-button primitive and a visual pass over the console"
    LEGACY_CHROME = "layout chrome (close/cancel/toggle) carries .btn plus focus-ring and absolute-positioning classes; render_button cannot emit that composite yet"
    LEGACY_SETTINGS_FORMS = "profile settings form controls carry .btn classes alongside Rails form builder attributes; moving them changes the emitted markup and needs a visual pass"
    LEGACY_BESPOKE = "bespoke .btn markup with per-surface rounded-full / size / state variants; render_button cannot express the variant today, needs a per-surface pass"

    # File-level allowlist. Each entry: relative path (String) => reason (String).
    # Reasons are committed next to the path so future maintainers know why
    # an exception is allowed.
    #
    # A value may also be a Hash scoping the exemption to specific rules —
    # `{ rules: %w[DS005], reason: "…" }` — so a legacy file can be waved
    # through one rule without losing the other thirteen.
    ALLOWLIST = {
      "app/views/articles/_card_cover.html.erb" => "procedural cover-art SVG (not an icon)",
      "app/javascript/utils/notify.js" => "toast icons migrated to i-[tabler--*]; allowlist shrinks in Phase 7",
      "app/assets/stylesheets/application.tailwind.css" => "source of token layer (hex literals are intentional)",
      "app/assets/stylesheets/lexxy_overrides.css" => "Lexxy editor internals; not owned by Quill",
      "app/views/admin/_aside.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/articles/_article.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/articles/_query.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/articles/index.html.erb" => { rules: %w[DS007], reason: LEGACY_ADMIN_TABLE },
      "app/views/admin/articles/show.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/bonuses/_bonus.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/bonuses/_form.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/bonuses/_query.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/bonuses/index.html.erb" => { rules: %w[DS005 DS007], reason: "#{LEGACY_ADMIN_TABLE} #{LEGACY_ADMIN_BUTTONS}" },
      "app/views/admin/collections/_query.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/collections/index.html.erb" => { rules: %w[DS007], reason: LEGACY_ADMIN_TABLE },
      "app/views/admin/collections/show.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/comments/_comment.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/comments/_query.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/comments/index.html.erb" => { rules: %w[DS007], reason: LEGACY_ADMIN_TABLE },
      "app/views/admin/login/new.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/mixin_network_snapshots/_mixin_network_snapshot.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/mixin_network_snapshots/_query.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/mixin_network_snapshots/index.html.erb" => { rules: %w[DS007], reason: LEGACY_ADMIN_TABLE },
      "app/views/admin/mixin_network_users/_mixin_network_user.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/mixin_network_users/_query.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/mixin_network_users/index.html.erb" => { rules: %w[DS007], reason: LEGACY_ADMIN_TABLE },
      "app/views/admin/mixin_network_users/show.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/orders/_order.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/orders/_query.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/orders/index.html.erb" => { rules: %w[DS007], reason: LEGACY_ADMIN_TABLE },
      "app/views/admin/payments/_payment.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/payments/_query.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/payments/index.html.erb" => { rules: %w[DS007], reason: LEGACY_ADMIN_TABLE },
      "app/views/admin/pre_orders/_pre_order.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/pre_orders/_query.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/pre_orders/index.html.erb" => { rules: %w[DS007], reason: LEGACY_ADMIN_TABLE },
      "app/views/admin/sessions/_query.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/sessions/index.html.erb" => { rules: %w[DS007], reason: LEGACY_ADMIN_TABLE },
      "app/views/admin/statistics/_query.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/statistics/index.html.erb" => { rules: %w[DS007], reason: LEGACY_ADMIN_TABLE },
      "app/views/admin/transfers/_query.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/transfers/_transfer.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/transfers/index.html.erb" => { rules: %w[DS007], reason: LEGACY_ADMIN_TABLE },
      "app/views/admin/users/_query.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/users/_user.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/users/index.html.erb" => { rules: %w[DS007], reason: LEGACY_ADMIN_TABLE },
      "app/views/admin/users/show.html.erb" => { rules: %w[DS005], reason: LEGACY_ADMIN_BUTTONS },
      "app/views/admin/wallets/assets.html.erb" => { rules: %w[DS007], reason: LEGACY_ADMIN_TABLE },
      "app/views/admin/wallets/safe_outputs.html.erb" => { rules: %w[DS007], reason: LEGACY_ADMIN_TABLE },
      "app/views/admin/wallets/snapshots.html.erb" => { rules: %w[DS007], reason: LEGACY_ADMIN_TABLE },
      "app/views/articles/_buy_article_button.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/articles/_conflict_resolution.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/articles/_edit_form.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/articles/_option_fields.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/articles/new.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/articles/preview.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/collections/_card.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/collections/_detail.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/collections/_form.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/comments/_actions.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/comments/_form.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/dashboard/access_tokens/_access_token.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/dashboard/access_tokens/_form.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/dashboard/access_tokens/create.turbo_stream.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/dashboard/articles/_drafted_article.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/dashboard/articles/index.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/dashboard/articles/show.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/dashboard/collections/index.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/dashboard/collections/new.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/dashboard/hidden_collections/new.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/dashboard/home/account.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/dashboard/home/index.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/dashboard/home/write.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/dashboard/listed_collections/new.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/dashboard/profile_settings/_avatar_field.html.erb" => { rules: %w[DS005], reason: LEGACY_SETTINGS_FORMS },
      "app/views/dashboard/profile_settings/_biography_field.html.erb" => { rules: %w[DS005], reason: LEGACY_SETTINGS_FORMS },
      "app/views/dashboard/profile_settings/_email_field.html.erb" => { rules: %w[DS005], reason: LEGACY_SETTINGS_FORMS },
      "app/views/dashboard/profile_settings/_name_field.html.erb" => { rules: %w[DS005], reason: LEGACY_SETTINGS_FORMS },
      "app/views/dashboard/profile_settings/edit.html.erb" => { rules: %w[DS005], reason: LEGACY_SETTINGS_FORMS },
      "app/views/dashboard/profile_settings/verify_email.html.erb" => { rules: %w[DS005], reason: LEGACY_SETTINGS_FORMS },
      "app/views/dashboard/published_articles/_form.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/dashboard/settings/_notification.html.erb" => { rules: %w[DS005], reason: LEGACY_SETTINGS_FORMS },
      "app/views/dashboard/settings/_profile.html.erb" => { rules: %w[DS005], reason: LEGACY_SETTINGS_FORMS },
      "app/views/flashes/_alert_content.html.erb" => { rules: %w[DS005], reason: LEGACY_CHROME },
      "app/views/pre_orders/_form.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/pre_orders/_pay_button.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/pre_orders/show.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/sessions/new.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/shared/_dashboard_rail.html.erb" => { rules: %w[DS005], reason: LEGACY_CHROME },
      "app/views/shared/_masthead.html.erb" => { rules: %w[DS005], reason: LEGACY_CHROME },
      "app/views/shared/_modal.html.erb" => { rules: %w[DS005], reason: LEGACY_CHROME },
      "app/views/shared/_navbar.html.erb" => { rules: %w[DS005], reason: LEGACY_CHROME },
      "app/views/subscribe_articles/_subscribe_button.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/subscribe_by_users/_subscribe_button.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/subscribe_tags/_subscribe_button.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE },
      "app/views/subscribe_users/_subscribe_button.html.erb" => { rules: %w[DS005], reason: LEGACY_BESPOKE }
    }.freeze

    HEX_RE = /(?<![0-9A-Za-z_])#[0-9A-Fa-f]{3,8}\b/.freeze

    # `render "shared/x"`, `render 'shared/x'`, `render partial: "shared/x"`,
    # with or without parens / trailing locals.
    RENDER_SHARED_RE = /\brender\b\s*\(?\s*(?:partial:\s*)?["']shared\/([\w]+)["']/.freeze

    # `render "shared/ui_input"` is a partial-path string, not a call to
    # `ui_input`. Strip every quoted string that names a shared partial so the
    # helper-name exemption on DS005/DS006/DS011-13 only fires for genuine
    # helper invocations.
    SHARED_PATH_STRING_RE = /["'][^"']*shared\/[\w]+["']/.freeze

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

    def whole_file_allowlisted?(rel)
      ALLOWLIST.key?(rel) && !ALLOWLIST.fetch(rel).is_a?(Hash)
    end

    # Rule ids a file is exempt from. A plain-String reason exempts the file
    # from everything; a `{ rules: […], reason: "…" }` entry scopes the
    # exemption so a legacy file keeps the other thirteen rules.
    def allowlisted_rules(rel)
      entry = ALLOWLIST[rel]
      return [] unless entry.is_a?(Hash)

      entry.fetch(:rules, [])
    end

    def scan_file(path)
      rel = path.sub(root.to_s + "/", "")
      return if whole_file_allowlisted?(rel)

      lines = File.readlines(path, encoding: "UTF-8", invalid: :replace, undef: :replace)
      exempt = allowlisted_rules(rel)
      count_before = violations.size

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
        check_direct_primitive_render!(rel, line, i + 1)
      end

      drop_exempt!(from: count_before, rules: exempt)
    end

    def drop_exempt!(from:, rules:)
      return if rules.empty?

      violations.reject!.with_index { |v, idx| idx >= from && rules.include?(v.rule_id) }
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
      return if helper_called_on_line?("render_button", line)
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
      return if helper_called_on_line?("render_chip", line)
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
      return if helper_called_on_line?("ui_input", line)
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
      return if helper_called_on_line?("render_modal", line)
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
      return if helper_called_on_line?("render_dropdown", line)
      return unless line.include?("<div ") && line.match?(/\bclass\s*=\s*["'][^"']*\bdropdown\b/i)

      violations << Violation.new(
        rule_id: "DS013",
        severity: :error,
        file: rel,
        line: ln,
        message: "raw `.dropdown` markup outside `shared/_dropdown.html.erb`; use `<%= render_dropdown … %>`",
      )
    end

    # DS014 — a direct `render "shared/<primitive>"` (or `render partial:`)
    # for a primitive that has a UiHelper wrapper. This polices the interface
    # rather than the markup: the partial is a primitive's implementation, the
    # helper is its contract, and the contract is where a signature change has
    # to land. app/views/shared/ is exempt — that is the implementation, and
    # primitives composing each other there is not a consumer bypass.
    def check_direct_primitive_render!(rel, line, ln)
      return unless rel.start_with?("app/views/")
      return if rel.start_with?("app/views/shared/")

      line.scan(RENDER_SHARED_RE).each do |match|
        name = match[0]
        helper = helpers_by_name[name.to_sym]
        next if helper.nil?

        violations << Violation.new(
          rule_id: "DS014",
          severity: :error,
          file: rel,
          line: ln,
          message: "renders `shared/#{name}` directly; use `<%= #{helper} … %>`",
        )
      end
    end

    # Registry lookup shared with the rule above.
    def helpers_by_name
      @helpers_by_name ||= DesignSystem::Primitives::Registry.all
                                                           .each_with_object({}) do |prim, index|
        index[prim[:name]] = prim[:helper] if prim[:helper]
      end
    end

    # True when `line` actually invokes the helper — `<%= render_button … %>`,
    # `ui_input form, :email` — and not merely mentions its name inside a
    # partial path (`render "shared/ui_input"`) or a comment.
    def helper_called_on_line?(helper, line)
      candidates = line.gsub(SHARED_PATH_STRING_RE, "")

      candidates.match?(/\b#{Regexp.escape(helper)}\b/)
    end
  end
end
