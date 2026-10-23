# frozen_string_literal: true

require "test_helper"

# Covers `DashboardHelper#dashboard_rail_sections`, the single source of
# truth for the five grouped dashboard nav destinations that
# `shared/_dashboard_rail` (desktop) and `shared/_dashboard_tabbar`
# (mobile) both render. The helper exists so the two shells can never
# diverge, which only holds if the section list itself stays stable.
class DashboardHelperTest < ActionView::TestCase
  test "lists the five grouped sections in navigation order" do
    assert_equal %i[overview write read finances account],
                 dashboard_rail_sections.map { |section| section[:section] }
  end

  test "every section carries a label, a path and an icon" do
    dashboard_rail_sections.each do |section|
      assert section[:label].present?, "#{section[:section]} has no label"
      assert section[:path].present?, "#{section[:section]} has no path"
      assert section[:icon].present?, "#{section[:section]} has no icon"
    end
  end

  test "section paths point at the canonical dashboard destinations" do
    assert_equal [
      dashboard_root_path,
      dashboard_write_path,
      dashboard_read_path,
      dashboard_finances_path,
      dashboard_account_path
    ], dashboard_rail_sections.map { |section| section[:path] }
  end

  test "labels are translated instead of falling back to a missing-translation string" do
    dashboard_rail_sections.each do |section|
      refute_match(/translation missing/i, section[:label])
    end
  end

  test "sections are unique so the rail and the tabbar cannot diverge" do
    sections = dashboard_rail_sections

    assert_equal sections.size, sections.map { |section| section[:section] }.uniq.size
    assert_equal sections.size, sections.map { |section| section[:path] }.uniq.size
  end
end
