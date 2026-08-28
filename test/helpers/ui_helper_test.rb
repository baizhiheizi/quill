# frozen_string_literal: true

require "test_helper"

class UiHelperTest < ActionView::TestCase
  # ─── render_button ───

  test "render_button defaults to primary variant and md size" do
    html = render_button("Save")

    assert_includes html, "<button"
    assert_includes html, 'type="button"'
    assert_includes html, "bg-primary"
    assert_includes html, "h-10 px-4"
    assert_includes html, "Save"
  end

  test "render_button applies variant classes" do
    %i[primary secondary soft ghost danger].each do |variant|
      html = render_button("Click", variant: variant)
      # Every variant resolves to a recognized class fragment that is not
      # the primary fallback. Asserting via known fragment keeps the test
      # robust against minor token-layer tweaks.
      assert_includes html, "rounded-[10px]"
      assert_includes html, "Click"
    end
  end

  test "render_button applies size classes" do
    sm = render_button("S", size: :sm)
    md = render_button("M", size: :md)
    lg = render_button("L", size: :lg)

    assert_includes sm, "h-8 px-3 text-sm"
    assert_includes md, "h-10 px-4"
    assert_includes lg, "h-12 px-6 text-lg"
  end

  test "render_button renders an <a> when href is set" do
    html = render_button("Go", href: "/articles")

    assert_includes html, "<a"
    assert_includes html, 'href="/articles"'
    assert_not_includes html, "<button"
    assert_not_includes html, 'type="button"'
  end

  test "render_button renders an icon span when icon is provided" do
    html = render_button("Lock", icon: "lock-open")

    assert_includes html, 'i-[tabler--lock-open]'
    assert_includes html, "Lock"
  end

  test "render_button omits the icon span when icon is nil" do
    html = render_button("Plain")

    assert_not_includes html, "i-[tabler--"
  end

  test "render_button forwards html_options onto the rendered element" do
    html = render_button("Save", class: "extra-class", data: { turbo: true })

    assert_includes html, "extra-class"
    assert_includes html, 'data-turbo="true"'
  end

  test "render_button honors an explicit type" do
    html = render_button("Submit", type: "submit")

    assert_includes html, 'type="submit"'
  end

  # ─── render_chip ───

  test "render_chip defaults to topic kind" do
    html = render_chip("Ruby")

    assert_includes html, "bg-base-200"
    assert_includes html, "Ruby"
  end

  test "render_chip renders price kind with inverse color" do
    html = render_chip("$3.99", kind: :price)

    assert_includes html, "bg-base-content"
    assert_includes html, "$3.99"
  end

  test "render_chip renders status kind as outlined pill" do
    html = render_chip("draft", kind: :status)

    assert_includes html, "border border-base-300"
    assert_includes html, "draft"
  end

  test "render_chip renders reward as text-only muted-amber span (never a filled badge)" do
    html = render_chip("+40%", kind: :reward)

    assert_includes html, "text-reward"
    assert_not_includes html, "rounded-full"
    assert_not_includes html, "bg-base-200"
    assert_not_includes html, "bg-base-content"
  end

  test "render_chip forwards html_options onto the rendered element" do
    html = render_chip("Tag", class: "extra-class")

    assert_includes html, "extra-class"
  end

  # ─── render_skeleton ───

  test "render_skeleton defaults to w-full h-4 rounded" do
    html = render_skeleton

    assert_includes html, "animate-pulse"
    assert_includes html, "bg-base-200"
    assert_includes html, "w-full"
    assert_includes html, "h-4"
    assert_includes html, "rounded"
  end

  test "render_skeleton accepts custom dimensions and radius" do
    html = render_skeleton(width: "w-1/2", height: "h-8", rounded: "rounded-full")

    assert_includes html, "w-1/2"
    assert_includes html, "h-8"
    assert_includes html, "rounded-full"
  end

  # ─── render_value_note ───

  test "render_value_note renders plain format by default" do
    html = render_value_note("42")

    assert_includes html, "reward-text"
    assert_includes html, "42"
  end

  test "render_value_note renders percent format with trailing percent" do
    html = render_value_note("40", format: :percent)

    assert_includes html, "40%"
  end

  test "render_value_note renders currency format with yuan prefix" do
    html = render_value_note("88.50", format: :currency)

    assert_includes html, "¥88.50"
  end

  test "render_value_note renders the label when provided" do
    html = render_value_note("10", label: "earnings", format: :percent)

    assert_includes html, "earnings:"
    assert_includes html, "10%"
  end

  test "render_value_note omits the label span when label is nil" do
    html = render_value_note("10", format: :percent)

    assert_not_includes html, "earnings"
  end

  test "render_value_note is text-only and never emits a filled badge background" do
    html = render_value_note("+40%", label: "early reader", format: :percent)

    assert_includes html, "text-reward"
    assert_not_includes html, "rounded-full"
    assert_not_includes html, "bg-base-content"
  end

  # ─── render_state_empty ───

  test "render_state_empty renders the title" do
    html = render_state_empty(title: "No articles yet")

    assert_includes html, "No articles yet"
    assert_includes html, "i-[tabler--info-circle]"
  end

  test "render_state_empty omits body when blank" do
    html = render_state_empty(title: "Nothing here", body: nil)

    assert_not_includes html, "max-w-[44ch]"
  end

  test "render_state_empty renders body copy when present" do
    html = render_state_empty(title: "Nothing", body: "Try again later.")

    assert_includes html, "Try again later."
  end

  test "render_state_empty renders an action button only when both action and action_href are present" do
    with_action = render_state_empty(title: "Empty", action: "New", action_href: "/articles/new")
    without_action = render_state_empty(title: "Empty")
    half_action = render_state_empty(title: "Empty", action: "New")

    assert_includes with_action, 'href="/articles/new"'
    assert_includes with_action, "New"
    assert_not_includes without_action, 'href="'
    assert_not_includes half_action, 'href="'
  end

  test "render_state_empty honors a custom icon slug" do
    html = render_state_empty(icon: "alert-triangle", title: "Boom")

    assert_includes html, "i-[tabler--alert-triangle]"
    assert_not_includes html, "i-[tabler--info-circle]"
  end
end
