# frozen_string_literal: true

# Helpers for the in-app design-system reference page.
#
# Most of the actual primitives (button, chip, list row, …) live in
# UiHelper (#render_button, #render_chip, …) and `app/views/shared/_*.html.erb`.
# This helper only owns the chrome of the reference page itself.

module DesignSystemHelper
  # Renders a labeled section on the design-system reference page.
  #
  # The block MUST render one example of the primitive being documented.
  # The section gets an anchor (so /design-system#buttons works), a heading,
  # an optional description, and a small "Source" link pointing at the
  # backing partial.
  def render_design_system_section(title:, description: nil, primitive: nil, &block)
    anchor = title.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/(^-|-$)/, "")

    source = primitive && DesignSystem::Primitives::Registry.all.find { |p| p[:name] == primitive.to_sym }
    source_path = source && source[:partial_path].sub("app/views/", "")

    desc_html = description ? content_tag(:p, description, class: "ds-section__desc mt-1 max-w-[60ch] text-base-content/60") : "".html_safe
    title_html = content_tag(:h2, title, class: "ds-section__title font-display text-2xl")
    title_block = content_tag(:div, safe_join([ title_html, desc_html ]))

    source_link = if source_path
      content_tag(:a, "Source", href: "/#{source_path}", class: "font-mono text-xs text-primary hover:underline")
    else
      "".html_safe
    end

    head_block = content_tag(:div, class: "ds-section__head mb-6 flex items-baseline justify-between gap-4") do
      safe_join([ title_block, source_link ])
    end

    body_block = capture(&block)

    content_tag(:section, id: anchor, class: "ds-section border-b border-base-300 py-12") do
      safe_join([ head_block, body_block ])
    end
  end
end
