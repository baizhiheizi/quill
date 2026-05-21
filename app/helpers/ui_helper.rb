# frozen_string_literal: true

module UiHelper
  BUTTON_VARIANTS = {
    primary: "btn-primary",
    secondary: "btn-secondary",
    soft: "btn-soft btn-primary",
    outline: "btn-outline btn-primary",
    ghost: "btn-text",
    danger: "btn-error",
    success: "btn-success"
  }.freeze

  BUTTON_SIZES = {
    xs: "btn-xs",
    sm: "btn-sm",
    md: "",
    lg: "btn-lg"
  }.freeze

  BADGE_VARIANTS = {
    default: "badge-neutral",
    primary: "badge-primary",
    success: "badge-success",
    warning: "badge-warning",
    error: "badge-error",
    info: "badge-info"
  }.freeze

  def render_modal(title: "", backdrop: "default", classes: "", header: nil, &block)
    render "shared/modal", title:, backdrop:, classes:, header:, content: capture(&block)
  end

  def render_dropdown(class: "", button:, &block)
    render "shared/dropdown", class:, button:, menu: capture(&block)
  end

  def render_time_format(datetime:, format: "long", class: nil, &block)
    render "shared/time_format", datetime:, format:, class:, content: capture(&block)
  end

  def render_qrcode(url:, image_classes: "", &block)
    render "shared/qrcode", url:, image_classes:, content: capture(&block)
  end

  def ui_button(label, variant: :primary, size: :md, type: "button", **options, &block)
    classes = [ "btn", BUTTON_VARIANTS.fetch(variant.to_sym), BUTTON_SIZES.fetch(size.to_sym) ].compact_blank.join(" ")
    classes = [ classes, options.delete(:class) ].compact_blank.join(" ")

    if block
      button_tag(type:, class: classes, **options, &block)
    else
      button_tag(label, type:, class: classes, **options)
    end
  end

  def ui_badge(label, variant: :default, **options)
    classes = [ "badge", BADGE_VARIANTS.fetch(variant.to_sym), options.delete(:class) ].compact_blank.join(" ")
    content_tag(:span, label, class: classes, **options)
  end

  def ui_input(form, field, label: nil, wrapper_class: nil, **options)
    render "shared/ui_input", form:, field:, label:, wrapper_class:, options:
  end

  def ui_card(title: nil, classes: nil, body_class: nil, &block)
    render "shared/ui_card", title:, classes:, body_class:, content: capture(&block)
  end
end
