# frozen_string_literal: true

module UiHelper
  def render_modal(title: "", backdrop: "default", classes: "", header: nil, &block)
    render "shared/modal", title:, backdrop:, classes:, header:, content: capture(&block)
  end

  def render_dropdown(class: "", button:, &block)
    render "shared/dropdown", class:, button:, menu: capture(&block)
  end

  def render_time_format(datetime:, format: "long", class: nil, &block)
    render "shared/time_format", datetime:, format:, class:, content: capture(&block)
  end

  def render_editor(draft_key: "", storage_endpoint: Settings.storage.endpoint, &block)
    render "shared/editor", draft_key:, storage_endpoint:, content: capture(&block)
  end

  def render_qrcode(url:, image_classes: "", &block)
    render "shared/qrcode", url:, image_classes:, content: capture(&block)
  end
end
