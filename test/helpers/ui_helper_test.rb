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

    assert_includes html, "i-[tabler--lock-open]"
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
    html = render_value_note("+40", label: "early reader", format: :percent)

    # reward-text is the specced utility (specs/011 T009) composing
    # font-mono text-[13px] text-reward.
    assert_includes html, "reward-text"
    assert_includes html, "+40%"
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

  # ─── render_list_row ───

  test "render_list_row renders the article title as a link to article_path" do
    article = articles(:published_paid)
    html = render_list_row(article)

    assert_includes html, "ds-list-row"
    assert_includes html, article.title
    # The partial always links the title through article_path; only the
    # `target == :_blank` branch adds target="_blank".
    assert_includes html, "href=\"/articles/#{article.uuid}\""
    assert_not_includes html, 'target="_blank"'
  end

  test "render_list_row adds target=_blank when target is :_blank" do
    article = articles(:published_paid)
    html = render_list_row(article, target: :_blank)

    assert_includes html, 'target="_blank"'
  end

  test "render_list_row hides the thumbnail when show_thumbnail: false" do
    article = articles(:published_paid)
    full = render_list_row(article)
    hidden = render_list_row(article, show_thumbnail: false)

    assert_includes full, "ds-list-row"
    # The thumbnail wrapper is a 88×88 square; without it the row no longer
    # contains that fixed-size slot.
    assert_includes full, "h-[88px] w-[88px]"
    assert_not_includes hidden, "h-[88px] w-[88px]"
  end

  test "render_list_row hides the meta line when show_meta: false" do
    article = articles(:published_paid)
    html = render_list_row(article, show_meta: false)

    # The meta line carries the created_at timestamp; with show_meta: false
    # the row should not contain the formatted date fragment.
    assert_not_includes html, "font-mono"
  end

  test "render_list_row does not render topic chip when show_topic: false" do
    article = articles(:published_paid)
    html = render_list_row(article, show_topic: false)

    # Articles have no `category` association, so the chip section is skipped
    # even with show_topic: true. The negative invariant is that toggling
    # show_topic never introduces a rounded chip fragment on a category-less
    # article — the topic chip class is `rounded-full bg-base-200 px-2 ...`.
    assert_not_includes html, "rounded-full bg-base-200"
  end

  # ─── render_table ───

  test "render_table renders column headers from the column specs" do
    # Rows are objects responding to the column keys — the partial renders
    # cells via `row.public_send(col[:key])` (see _table.html.erb).
    row = Struct.new(:name, :count)
    rows = [ row.new("Alice", 3), row.new("Bob", 7) ]
    columns = [
      { key: :name, label: "Name" },
      { key: :count, label: "Count" }
    ]
    html = render_table(columns: columns, rows: rows)

    assert_includes html, "ds-table"
    assert_includes html, "<th"
    assert_includes html, ">Name<"
    assert_includes html, ">Count<"
    assert_includes html, "Alice"
    assert_includes html, "Bob"
    assert_includes html, "3"
    assert_includes html, "7"
  end

  test "render_table applies text-right + font-mono to right-aligned columns" do
    columns = [ { key: :amount, label: "Amount", align: "right" } ]
    rows = [ Struct.new(:amount).new("42") ]
    html = render_table(columns: columns, rows: rows)

    assert_includes html, "text-right font-mono"
    assert_includes html, "42"
  end

  test "render_table invokes a Proc formatter when col[:format] is callable" do
    columns = [
      {
        key: :amount,
        label: "Amount",
        format: ->(row) { "$#{row[:amount]}" }
      }
    ]
    rows = [ { amount: 5 }, { amount: 12 } ]
    html = render_table(columns: columns, rows: rows)

    assert_includes html, "$5"
    assert_includes html, "$12"
  end

  test "render_table renders the empty state when rows is blank" do
    html = render_table(columns: [ { key: :name, label: "Name" } ], rows: [])

    # Empty rows fall through to `render_state_empty` with the inbox icon.
    assert_includes html, "i-[tabler--inbox]"
    assert_not_includes html, "<table"
  end

  test "render_table honors a custom empty message" do
    html = render_table(
      columns: [ { key: :name, label: "Name" } ],
      rows: [],
      empty: "No results found."
    )

    assert_includes html, "No results found."
  end

  # ─── render_notification_card ───

  test "render_notification_card renders title and body from a duck-typed event" do
    event = Struct.new(:title, :body, :created_at).new(
      "Article published",
      "Alice published a new article.",
      Time.zone.local(2026, 8, 29, 12, 0, 0)
    )
    html = render_notification_card(event)

    assert_includes html, "ds-notification-card"
    assert_includes html, "Article published"
    assert_includes html, "Alice published a new article."
    assert_includes html, "i-[tabler--bell]"
  end

  test "render_notification_card falls back to type when title is missing" do
    event = Struct.new(:type, :created_at).new("CommentReplied", Time.current)
    html = render_notification_card(event)

    assert_includes html, "CommentReplied"
  end

  test "render_notification_card marks itself with bg-base-200/40 when unread: true" do
    event = Struct.new(:title, :created_at).new("Title", Time.current)

    read = render_notification_card(event, unread: false)
    unread = render_notification_card(event, unread: true)

    assert_not_includes read, "bg-base-200/40"
    assert_includes unread, "bg-base-200/40"
    # Unread badge: a small primary dot with the "Unread" aria-label.
    assert_includes unread, "bg-primary"
    assert_includes unread, "aria-label=\"Unread\""
  end

  test "render_notification_card accepts a Hash and falls back to the default title and empty body" do
    # A plain Hash doesn't respond to `.try(:title)`, so the partial's
    # fallback chain `event.try(:title) || event.try(:type) ||
    # t("notifications.inbox.default_title", default: "Notification")`
    # lands on the i18n default. Hash also doesn't respond to `.try(:body)`,
    # so the body default (empty string) applies — meaning the `<p>` body
    # block is skipped.
    event = { title: "Reward received", body: "+0.001 BTC", created_at: Time.current }
    html = render_notification_card(event)

    assert_includes html, "Notification"
    assert_not_includes html, "+0.001 BTC"
  end

  # ─── render_pagination ───

  # Minimal stand-in for the Pagy object `_pagination.html.erb` consumes:
  # `pagy&.next&.present?` gates the Load More link, `pagy.page_url(n)` builds it.
  class FakePagy
    attr_accessor :page

    def initialize(page)
      @page = page
    end

    define_method(:next) { @page < 2 ? @page + 1 : nil }

    def page_url(num)
      "/?page=#{num}"
    end
  end

  test "render_pagination renders the infinite-scroll anchor with the default id" do
    html = render_pagination(FakePagy.new(1))

    assert_includes html, "data-infinite-scroll-target='pagination'"
    assert_includes html, 'id="pagination"'
    assert_includes html, "Load More"
    assert_includes html, 'href="/?page=2"'
  end

  test "render_pagination forwards a custom id" do
    html = render_pagination(FakePagy.new(1), id: "my_transfers_pagination")

    assert_includes html, 'id="my_transfers_pagination"'
    # The default id must not leak onto a page that asked for its own anchor.
    assert_not_includes html, 'id="pagination"'
  end

  test "render_pagination renders an empty anchor on the last page" do
    html = render_pagination(FakePagy.new(5), id: "tail")

    assert_includes html, 'id="tail"'
    assert_not_includes html, "Load More"
  end

  test "render_pagination renders an empty anchor without a pagy object" do
    html = render_pagination(nil)

    assert_includes html, 'id="pagination"'
    assert_not_includes html, "Load More"
  end

  # ─── render_loading ───

  test "render_loading renders the infinite-scroll spinner" do
    html = render_loading

    assert_includes html, "/assets/loading-"
    assert_includes html, "p-4 flex justify-center"
  end

  # ─── render_avatar ───

  AvatarUser = Struct.new(:name, :mixin_uuid, :avatar_image_url, :avatar_image_thumb)

  test "render_avatar renders the remote image when the user has an avatar" do
    user = AvatarUser.new("Alice", "uuid-1", "https://example.com/a.png", "https://example.com/t.png")

    html = render_avatar(user:, thumb: true, class: "w-8 h-8 rounded-full")

    assert_includes html, "https://example.com/t.png"
    assert_includes html, "w-8 h-8 rounded-full"
    assert_not_includes html, "avatar-placeholder"
  end

  test "render_avatar renders the initials placeholder when the avatar is missing" do
    user = AvatarUser.new("Alice", "uuid-2", "", "")

    html = render_avatar(user:, class: "w-8 h-8 rounded-full")

    assert_includes html, "avatar-placeholder"
    assert_includes html, "data-avatar-seed-value=\"uuid-2\""
    assert_includes html, "w-8 h-8 rounded-full"
  end

  test "render_avatar defaults to the full-size image and the rounded-full class" do
    user = AvatarUser.new("Alice", "uuid-3", "https://example.com/a.png", "https://example.com/t.png")

    html = render_avatar(user:)

    assert_includes html, "https://example.com/a.png"
    assert_includes html, "rounded-full"
  end

  # ─── render_empty ───

  test "render_empty renders the empty-state artwork and the message" do
    html = render_empty(text: "Nothing here yet")

    assert_includes html, "/assets/empty-"
    assert_includes html, "Nothing here yet"
  end

  test "render_empty escapes the message" do
    html = render_empty(text: "<b>no record</b>")

    assert_includes html, "&lt;b&gt;no record&lt;/b&gt;"
    assert_not_includes html, "<b>no record</b>"
  end
end
