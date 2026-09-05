# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

# Coverage for the rules that police the design-system *interface* (DS014) and
# for the allowlist semantics those rules depend on.
#
# The scanner walks a throwaway directory tree, not the real app, so each case
# states exactly the input it exercises.
class DesignSystem::LintTest < ActiveSupport::TestCase
  test "DS014 flags a direct render of a primitive that has a helper" do
    violations = scan("app/views/articles/index.html.erb", %(<%= render "shared/button", label: "Save" %>))

    assert_violation violations, "DS014", /use `<%= render_button … %>`/
  end

  test "DS014 names the helper to call in its message" do
    violations = scan("app/views/dashboard/home/index.html.erb", %(<%= render "shared/pagination", pagy: @pagy %>))

    assert_includes violations.first.message, "render_pagination"
  end

  test "DS014 catches the partial:/locals: variant and the single-quoted variant" do
    variants = [
      "<%= render partial: \"shared/avatar\", locals: { user: u } %>",
      "<%= render 'shared/empty', text: t('no_record') %>",
      "<%= render(\"shared/loading\") %>"
    ]

    variants.each do |line|
      violations = scan("app/views/users/show.html.erb", line)

      assert_violation violations, "DS014", /shared\//
    end
  end

  test "DS014 ignores primitives with no helper" do
    violations = scan("app/views/layouts/application.html.erb", %(<%= render "shared/masthead" %>))

    assert_empty violations.select { |v| v.rule_id == "DS014" }
  end

  test "DS014 ignores the shared partials themselves" do
    violations = scan("app/views/shared/_dashboard_rail.html.erb", %(<%= render "shared/button", label: "Save" %>))

    assert_empty violations.select { |v| v.rule_id == "DS014" }
  end

  test "DS014 ignores helper calls and non-view files" do
    assert_empty scan("app/views/users/show.html.erb", %(<%= render_button "Save" %>))
    assert_empty scan("app/helpers/ui_helper.rb", %(render "shared/button", label:, variant:))
  end

  test "DS014 reports one violation per bypass on a line" do
    line = %(<%= render "shared/loading" %><%= render "shared/empty", text: "x" %>)
    violations = scan("app/views/articles/show.html.erb", line)

    assert_equal 2, violations.count { |v| v.rule_id == "DS014" }
  end

  # ─── corrected exemptions: helper *calls*, not helper names in a path ───

  test "a partial path string no longer exempts the raw markup on the same line" do
    # The old exemption was `line.include?("ui_input")`, so a raw input whose
    # line mentioned the shared/ui_input path escaped DS011.
    line = %(<input class="input input-bordered" data-source="shared/ui_input">)
    violations = scan("app/views/dashboard/profiles/edit.html.erb", line)

    assert_violation violations, "DS011", /ui_input/
  end

  test "a genuine helper call still exempts the raw markup on the same line" do
    line = %(<%= ui_input form, :email %><input class="input input-bordered">)
    violations = scan("app/views/dashboard/profiles/edit.html.erb", line)

    assert_empty violations.select { |v| v.rule_id == "DS011" }
  end

  test "the corrected exemption applies to DS005, DS006, DS012 and DS013 too" do
    assert_empty scan("app/views/x/a.html.erb", %(<%= render_button "Go" %> <button class="btn btn-primary">)), "DS005"
    assert_empty scan("app/views/x/b.html.erb", %(<%= render_chip "Go" %> <span class="chip chip-topic">)), "DS006"
    assert_empty scan("app/views/x/c.html.erb", %(<%= render_modal title: "t" do %><div class="modal"><% end %>)), "DS012"
    assert_empty scan("app/views/x/d.html.erb", %(<%= render_dropdown button: "b" do %><div class="dropdown"><% end %>)), "DS013"
  end

  test "raw markup on a line that only names the partial path is reported for DS005/DS006/DS012/DS013" do
    cases = {
      %(<button class="btn btn-primary" data-tpl="shared/button">) => "DS005",
      %(<span class="chip chip-topic" data-tpl="shared/chip">) => "DS006",
      %(<div class="modal" data-tpl="shared/modal">) => "DS012",
      %(<div class="dropdown" data-tpl="shared/dropdown">) => "DS013"
    }

    cases.each do |line, rule|
      violations = scan("app/views/x/legacy.html.erb", line)

      assert_violation violations, rule, /shared/
    end
  end

  # ─── allowlist semantics ───

  test "a rule-scoped allowlist entry suppresses only the named rules" do
    with_allowlist({ rules: %w[DS005], reason: "legacy admin markup" }) do
      violations = scan(
        "app/views/legacy/index.html.erb",
        "<span class=\"btn btn-primary\">go</span>\n<%= render \"shared/button\", label: \"go\" %>"
      )

      assert_empty violations.select { |v| v.rule_id == "DS005" }
      assert violations.any? { |v| v.rule_id == "DS014" }, "DS014 must still fire in a rule-scoped file"
    end
  end

  test "a plain-string allowlist entry still exempts the whole file" do
    with_allowlist("hand-migrated elsewhere") do
      violations = scan("app/views/legacy/index.html.erb", %(<%= render "shared/button" %>))

      assert_empty violations
    end
  end

  test "the shipped allowlist entries are either a reason or a scoped rules+reason hash" do
    DesignSystem::Lint::ALLOWLIST.each do |path, entry|
      reason = entry.is_a?(Hash) ? entry[:reason] : entry

      assert reason.present?, "allowlist entry for #{path} must cite a reason"
      assert entry.is_a?(String) || entry[:rules].present?,
             "allowlist entry for #{path} must be a reason or { rules:, reason: }"
    end
  end

  test "every allowlisted path still exists, so entries cannot outlive their file" do
    DesignSystem::Lint::ALLOWLIST.each_key do |path|
      assert Rails.root.join(path).exist?,
             "allowlist entry #{path} points at a file that no longer exists — delete the entry"
    end
  end

  test "rule-scoped entries never name a rule that does not exist" do
    DesignSystem::Lint::ALLOWLIST.each do |path, entry|
      next unless entry.is_a?(Hash)

      entry[:rules].each do |rule|
        assert_match(/\ADS\d{3}\z/, rule, "#{path} allowlists an unparsable rule id")
      end
    end
  end

  private

  # ALLOWLIST is a frozen constant, so swap it wholesale for the duration of a
  # block and put the real one back.
  def with_allowlist(entry)
    original = DesignSystem::Lint::ALLOWLIST
    DesignSystem::Lint.send(:remove_const, :ALLOWLIST)
    DesignSystem::Lint.const_set(:ALLOWLIST, { "app/views/legacy/index.html.erb" => entry }.freeze)
    yield
  ensure
    DesignSystem::Lint.send(:remove_const, :ALLOWLIST)
    DesignSystem::Lint.const_set(:ALLOWLIST, original)
  end

  def scan(path, line)
    with_root(path => line) do |root|
      DesignSystem::Lint.run(root)
    end
  end

  def with_root(files)
    Dir.mktmpdir do |dir|
      files.each do |path, body|
        full = File.join(dir, path)
        FileUtils.mkdir_p(File.dirname(full))
        File.write(full, "#{body}\n")
      end

      yield dir
    end
  end

  def assert_violation(violations, rule_id, message = nil)
    found = violations.select { |v| v.rule_id == rule_id }

    assert found.any?, "expected a #{rule_id} violation, got #{violations.map(&:rule_id).uniq}"
    assert found.any? { |v| v.message.match?(message) }, "no #{rule_id} message matched #{message}" if message
  end
end
