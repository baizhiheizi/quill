# frozen_string_literal: true

Benchmarks::Runner.register("article_search.popularity") do
  reader = users(:reader_one)
  ArticleSearchService.call(current_user: reader).to_a
end

Benchmarks::Runner.register("article_search.bought") do
  buyer = users(:reader_one)
  ArticleSearchService.call(filter: "bought", current_user: buyer).to_a
end

Benchmarks::Runner.register("article_search.subscribed") do
  reader = users(:reader_one)
  ArticleSearchService.call(filter: "subscribed", current_user: reader).to_a
end

Benchmarks::Runner.register("article.random_readers") do
  article = articles(:published_paid)
  article.random_readers(24).to_a
end

# Mirror of `HomeController#active_authors` for the signed-out path
# (no per-visitor blocked-user filter — all visitors share the same sample).
# Uses `ORDER BY RANDOM() LIMIT 5` so Postgres picks 5 rows directly; the
# previous shape loaded `.limit(20)` and discarded 15 in Ruby.
Benchmarks::Runner.register("home.active_authors") do
  User.active.where(locale: :en).order(Arel.sql("RANDOM()")).limit(5).to_a
end

# Pre-optimisation shape, kept around for direct A/B comparison.
Benchmarks::Runner.register("home.active_authors.legacy") do
  User.active.where(locale: :en).limit(20).sample(5)
end

# Mirror of the eager-load shape introduced for
# `Dashboard::OrdersController#index` (see PR #1843 follow-up). Uses the
# same `citer: :author` + `buyer: user_field_preloads` chain that the
# controller passes to `.includes(...)`, so the benchmark captures the
# full partial-render SQL cost (preload SELECTs + ActiveStorage blob +
# variant_record fan-out + authorization lookup) end to end.
USER_FIELD_PRELOADS = [
  :authorization,
  {
    avatar_attachment: {
      blob: {
        variant_records: { image_attachment: :blob },
        preview_image_attachment: { blob: { variant_records: { image_attachment: :blob } } }
      }
    }
  }
].freeze

Benchmarks::Runner.register("dashboard.orders.eager_load") do
  article = articles(:published_paid)
  article.orders
    .includes(:item, :currency, citer: :author, buyer: USER_FIELD_PRELOADS)
    .order(created_at: :desc)
    .to_a
    .each { |o| o.buyer.avatar_image_thumb; o.citer.author.name if o.citer.is_a?(Article) }
end

# Pre-optimisation shape for direct A/B comparison.
Benchmarks::Runner.register("dashboard.orders.legacy") do
  article = articles(:published_paid)
  article.orders
    .order(created_at: :desc)
    .to_a
    .each { |o| o.buyer.avatar_image_thumb; o.citer.author.name if o.citer.is_a?(Article) }
end

Benchmarks::Runner.setup("article_search.bought") do
  article = articles(:published_paid)
  buyer = users(:reader_one)

  with_quill_bot_stub do
    create_buy_order!(article: article, buyer: buyer)
  end
end

Benchmarks::Runner.setup("article_search.subscribed") do
  reader = users(:reader_one)
  author = users(:author)
  reader.create_action(:subscribe, target: author) unless reader.subscribe_user?(author)
end

Benchmarks::Runner.setup("article.random_readers") do
  article = articles(:published_paid)
  buyer = users(:reader_one)

  with_quill_bot_stub do
    create_buy_order!(article: article, buyer: buyer) unless article.orders.exists?
  end
end
