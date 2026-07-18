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

# Mirror of `Admin::MixinNetworkSnapshotsController#index` after PR #1868
# follow-up: the four belongs_to + the opponent avatar field chain are
# eagerly loaded in one pass. Without this prime the partial fires
# ~4 SELECTs/row + ~5 SELECTs/row for the opponent avatar chain.
Benchmarks::Runner.register("admin.mixin_network_snapshots.eager_load") do
  MixinNetworkSnapshot
    .includes(:wallet, :opponent_wallet, :currency, opponent: USER_FIELD_PRELOADS)
    .order(created_at: :desc)
    .limit(50)
    .to_a
    .each do |s|
      s.wallet&.uuid
      s.opponent_wallet&.uuid
      s.currency&.icon_url
      s.opponent&.avatar_image_thumb
    end
end

# Mirror of `Admin::MixinNetworkUsersController#index` after the owner
# avatar preload chain is added: the polymorphic `:owner` is grouped by
# `owner_type` (Rails 7+) and User-owner rows additionally get the
# `user_field_preloads` chain primed in IN-batched SELECTs. Article-owner
# rows ignore the user-shaped keys (no avatar chain) so the second
# `includes` line costs nothing on that branch.
Benchmarks::Runner.register("admin.mixin_network_users.eager_load") do
  MixinNetworkUser
    .includes(owner: USER_FIELD_PRELOADS)
    .order(created_at: :desc)
    .limit(50)
    .to_a
    .each do |u|
      # Walks the polymorphic dispatch: Article-owner rows hit
      # `admin/articles/_field` (no avatar), User-owner rows hit
      # `admin/users/_field` → `shared/_avatar` (4-5 SELECTs without the
      # preload chain above).
      owner = u.owner
      next unless owner.is_a?(User)

      owner.avatar_image_thumb
    end
end

# Pre-optimisation shape for direct A/B comparison — the per-row N+1
# fan-out this PR closes.
Benchmarks::Runner.register("admin.mixin_network_snapshots.legacy") do
  MixinNetworkSnapshot
    .order(created_at: :desc)
    .limit(50)
    .to_a
    .each do |s|
      s.wallet&.uuid
      s.opponent_wallet&.uuid
      s.currency&.icon_url
      s.opponent&.avatar_image_thumb
    end
end

# Mirror of `ArticlesController#show` (`Article.with_show_associations`)
# driving the `articles/_references_card.html.erb` partial walk: each
# reference loads its polymorphic `reference` + `reference.author` + the
# `shared/_avatar` chain. Without the nested preload this PR adds,
# each reference fires ~5 SELECTs.
Benchmarks::Runner.register("article.show_references.eager_load") do
  Article.with_show_associations
    .where.not(id: nil)
    .to_a
    .each do |a|
      a.article_references.each do |r|
        r.reference.author.avatar_image_thumb if r.reference.respond_to?(:author)
      end
    end
end

# Pre-optimisation shape for direct A/B comparison.
Benchmarks::Runner.register("article.show_references.legacy") do
  Article
    .where.not(id: nil)
    .to_a
    .each do |a|
      a.article_references.each do |r|
        r.reference.author.avatar_image_thumb if r.reference.respond_to?(:author)
      end
    end
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

# Mirror of `Admin::UsersController#index` after the avatar-chain preload
# added in `perf-assist/admin-users-avatar-preload-20260714`. The
# `_user` partial renders `admin/users/_field`, which walks the
# `shared/_avatar` chain (`authorization.raw["avatar_url"]` +
# `avatar_attachment.blob.variant_records`). Without the preload, each
# row triggers ~3-5 SELECTs. With it, the chain is resolved in O(1)
# SELECTs regardless of page size.
Benchmarks::Runner.register("admin.users.eager_load") do
  User
    .includes(*USER_FIELD_PRELOADS)
    .order(created_at: :desc)
    .limit(24)
    .to_a
    .each { |u| u.avatar_image_thumb }
end

# Pre-optimisation shape for direct A/B comparison — the per-row N+1
# fan-out this fix closes.
Benchmarks::Runner.register("admin.users.legacy") do
  User
    .order(created_at: :desc)
    .limit(24)
    .to_a
    .each { |u| u.avatar_image_thumb }
end

# Mirror of `API::ArticlesController#index`: the jbuilder reads
# `article.author.avatar_image_url`, which walks
# `avatar_attachment → blob` plus the `authorization` fallback. Without
# the preload chain each row fires 2-4 SELECTs; at `limit: 100` that's
# up to ~400 fan-out SELECTs per request.
Benchmarks::Runner.register("api.articles.eager_load") do
  Article
    .only_published
    .limit(20)
    .includes(:tags, :currency, author: USER_FIELD_PRELOADS)
    .to_a
    .each { |a| a.author.avatar_image_url }
end

# Pre-optimisation shape for direct A/B comparison.
Benchmarks::Runner.register("api.articles.legacy") do
  Article
    .only_published
    .limit(20)
    .includes(:tags, :currency)
    .to_a
    .each { |a| a.author.avatar_image_url }
end
