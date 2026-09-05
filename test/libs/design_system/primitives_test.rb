# frozen_string_literal: true

require "test_helper"

# Registry contract: the primitive registry, the filesystem, and UiHelper
# must agree. The registry is derived, not hand-maintained — these tests turn
# any drift back into a failure instead of a silent mismatch.
#
#   partial (app/views/shared/_x.html.erb)
#     ⇔ registry entry { name: :x, partial_path: "...", helper: ... }
#     ⇔ UiHelper#render_x (or UiHelper#x for the ui_card / ui_input pair)
class DesignSystem::PrimitivesTest < ActiveSupport::TestCase
  test "registers exactly the partials on disk, in sort order" do
    on_disk = Dir.glob(Rails.root.join("app/views/shared", "_*.html.erb"))
                 .sort
                 .map { |p| p.sub(Rails.root.to_s + "/", "") }

    registered = DesignSystem::Primitives::Registry.all

    assert_equal on_disk, registered.map { |p| p[:partial_path] },
                 "the registry and app/views/shared/_*.html.erb disagree"
  end

  test "derives name from the partial filename" do
    DesignSystem::Primitives::Registry.all.each do |prim|
      expected = File.basename(prim[:partial_path], ".html.erb").sub(/^_/, "")

      assert_equal expected, prim[:name].to_s
    end
  end

  test "every helper points at a real UiHelper instance method" do
    DesignSystem::Primitives::Registry.all.each do |prim|
      next if prim[:helper].nil?

      assert UiHelper.method_defined?(prim[:helper]),
             "registry entry #{prim[:name]} maps to #{prim[:helper]}, " \
             "which UiHelper does not define"
    end
  end

  test "every UiHelper wrapper is registered against the partial it renders" do
    UiHelper.instance_methods(false).each do |helper|
      registered = DesignSystem::Primitives::Registry.all.find { |p| p[:helper] == helper }

      assert registered, "UiHelper##{helper} renders a shared partial but no " \
                         "registry entry claims it — the primitive is invisible " \
                         "to /design-system and to the lint"
      assert registered[:partial_path].end_with?("_#{registered[:name]}.html.erb")
    end
  end

  test "helper names follow the render_<primitive> (or <primitive>) convention" do
    DesignSystem::Primitives::Registry.all.each do |prim|
      next if prim[:helper].nil?

      expected = [ :"render_#{prim[:name]}", prim[:name].to_sym ]

      assert_includes expected, prim[:helper],
                      "#{prim[:helper]} does not follow the render_<primitive> " \
                      "convention — the derivation in Registry.helper_for will " \
                      "not survive a rename"
    end
  end

  test "every wrapper body renders the partial its registry entry names" do
    DesignSystem::Primitives::Registry.all.each do |prim|
      next if prim[:helper].nil?

      source = UiHelper.instance_method(prim[:helper]).source_location
      body = File.read(source.first)
      rendered_as = prim[:partial_path]
                    .delete_prefix("app/views/")
                    .delete_suffix(".html.erb")
                    .sub(/\/_/, "/")

      assert_includes body, %("#{rendered_as}"),
                     "UiHelper##{prim[:helper]} no longer renders #{prim[:partial_path]}"
    end
  end

  test "helper coverage is reported by the registry" do
    counted = DesignSystem::Primitives::Registry.all.count { |p| p[:helper] }

    assert counted.positive?, "no primitive is reachable through a helper"
  end

  test "reset! re-derives the registry" do
    before = DesignSystem::Primitives::Registry.all

    DesignSystem::Primitives::Registry.reset!

    assert_equal before, DesignSystem::Primitives::Registry.all
  end
end
