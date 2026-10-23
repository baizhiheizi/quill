# frozen_string_literal: true

require "test_helper"

# Covers `DesignSystemHelper#render_design_system_section`, the chrome
# helper behind the /design-system reference page. Each call renders a
# <section> carrying an anchor derived from the title, a heading, an
# optional description, an optional "Source" link and the block's own
# content.
class DesignSystemHelperTest < ActionView::TestCase
  test "renders a section with an anchor derived from the title" do
    html = render_design_system_section(title: "Buttons") { "Example" }

    assert_includes html, "<section"
    assert_includes html, 'id="buttons"'
    assert_includes html, "Buttons"
  end

  test "anchor is slugified for multi-word titles" do
    html = render_design_system_section(title: "List row") { "Example" }

    assert_includes html, 'id="list-row"'
  end

  test "renders the description when one is given" do
    html = render_design_system_section(title: "Chips", description: "One neutral chip.") { "Example" }

    assert_includes html, "One neutral chip."
    assert_includes html, "ds-section__desc"
  end

  test "omits the description paragraph when no description is given" do
    html = render_design_system_section(title: "Type") { "Example" }

    refute_includes html, "ds-section__desc"
  end

  test "renders the block content inside the section" do
    html = render_design_system_section(title: "Chips") { "Example" }

    assert_includes html, "Example"
  end

  test "links to the source partial for a registered primitive" do
    html = render_design_system_section(title: "Buttons", primitive: :button) { "Example" }

    assert_includes html, ">Source</a>"
    assert_includes html, "_button.html.erb"
  end

  test "omits the source link when no primitive is given" do
    html = render_design_system_section(title: "Type") { "Example" }

    refute_includes html, ">Source</a>"
  end

  test "omits the source link when the primitive is not registered" do
    html = render_design_system_section(title: "Type", primitive: :not_a_registered_primitive) { "Example" }

    refute_includes html, ">Source</a>"
  end
end
