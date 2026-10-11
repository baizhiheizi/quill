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

  # ─── specs/011-comprehensive-ui-refactor — design-system primitive helpers ───
  # Each helper wraps a single shared partial under app/views/shared/_*.html.erb.
  # See specs/011-comprehensive-ui-refactor/contracts/primitives.md.

  def render_button(label, variant: :primary, size: :md, icon: nil, href: nil, type: "button", **html_options)
    render "shared/button", label:, variant:, size:, icon:, href:, type:, html_options:
  end

  def render_chip(label, kind: :topic, **html_options)
    render "shared/chip", label:, kind:, html_options:
  end

  def render_list_row(article, **opts)
    render "shared/list_row", article:, **opts
  end

  def render_value_note(value, label: nil, format: :plain)
    render "shared/value_note", value:, label:, format:
  end

  def render_notification_card(event, unread: false)
    render "shared/notification_card", event:, unread:
  end

  def render_skeleton(width: "w-full", height: "h-4", rounded: "rounded")
    render "shared/skeleton", width:, height:, rounded:
  end

  def render_state_empty(icon: "info-circle", title:, body: nil, action: nil, action_href: nil)
    render "shared/state_empty", icon:, title:, body:, action:, action_href:
  end

  def render_table(columns:, rows:, row_path: nil, empty: nil)
    render "shared/table", columns:, rows:, row_path:, empty:
  end

  # Infinite-scroll pagination footer (`app/views/shared/_pagination.html.erb`).
  # `id` is the DOM anchor Turbo appends the next page after; it defaults to
  # "pagination" inside the partial. Pass `id:` whenever more than one paginated
  # list can appear on the same page.
  def render_pagination(pagy, id: nil)
    render "shared/pagination", pagy:, id:
  end

  # Inline infinite-scroll spinner (`app/views/shared/_loading.html.erb`).
  def render_loading
    render "shared/loading"
  end

  # User avatar with initials fallback (`app/views/shared/_avatar.html.erb`).
  # `class:` is passed through verbatim; the partial falls back to
  # "rounded-full" when it is blank.
  def render_avatar(user:, thumb: false, class: nil)
    render "shared/avatar", user:, thumb:, class:
  end

  # Empty-list placeholder (`app/views/shared/_empty.html.erb`).
  def render_empty(text:)
    render "shared/empty", text:
  end
end
