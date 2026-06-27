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
