# frozen_string_literal: true

module UiHelper
  def render_modal(title: "", backdrop: "default", classes: "", dialog_class: "", header: nil, &block)
    render "shared/modal", title:, backdrop:, classes:, dialog_class:, header:, content: capture(&block)
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

  def ui_input(form, field, label: nil, wrapper_class: nil, **options)
    render "shared/ui_input", form:, field:, label:, wrapper_class:, options:
  end

  def ui_card(title: nil, classes: nil, body_class: nil, &block)
    render "shared/ui_card", title:, classes:, body_class:, content: capture(&block)
  end
end
