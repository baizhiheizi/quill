# frozen_string_literal: true

# The single answer to the platform's core question: which articles (and which
# authors) may this viewer see?
#
# Four surfaces used to re-derive that answer with four different dialects
# (issue #2075): the web feed, the JSON API index, the home page's
# active-authors frame and the article-reference picker. Every predicate that
# decides visibility now lives here — and only here:
#
#   * `for(viewer)`      — the article scope a viewer may list
#   * `authors(viewer)`  — the author scope a viewer may list
#   * `cap` / `cap_each` — the one definition of the query-length cap
#
# A surface that lists access rather than discovery (things the viewer already
# bought, the article-reference picker) passes `hide_blocked_authors: false` so
# the rule is skipped *visibly* at the call site instead of by accident.
#
# `for(viewer)` returns a relation extended with the chainable builders in
# `Query`, so a surface states its intent (`searching`, `tagged`, `in_range`,
# `ordered_by`, `subscribed_to`, `bought_by`) instead of assembling a Ransack
# hash or an inline SQL subquery.
#
# The rule itself: an author is hidden from `viewer` when either side blocked
# the other. `viewer` is never hidden from themself, so the predicate is safe
# to apply to any candidate set — including the viewer's own articles.
module ArticleVisibility
  # Cap query length so a long `query` param can't bloat the ILIKE pattern
  # into an expensive seq-scan. Pairs with the pg_trgm GIN indexes (see
  # db/migrate/*_add_pg_trgm_indexes_for_search.rb).
  QUERY_LENGTH_LIMIT = 64

  # Fields a text search matches by default. The web feed and the
  # article-reference picker use all of them; `API::ArticlesController#index`
  # narrows to `%i[title intro tags]` because its search contract is frozen —
  # widening it would change result sets for existing API consumers.
  SEARCH_FIELDS = %i[title intro author tags].freeze

  # Field → the Ransack predicate that matches it. `author` and `tags` name
  # the association *and* the column searched through it, so the mapping is
  # explicit rather than derived from the field name.
  SEARCH_PREDICATES = {
    title: "title_i_cont_any",
    intro: "intro_i_cont_any",
    author: "author_name_i_cont_any",
    tags: "tags_name_i_cont_any"
  }.freeze

  # The orderings any article surface may ask for. Anything else raises rather
  # than silently falling back to the default sort.
  ORDERS = {
    popularity: -> { order_by_popularity },
    recent: -> { order(published_at: :desc) },
    revenue: -> { order_by_revenue_usd },
    oldest: -> { order(created_at: :asc) },
    newest: -> { order(created_at: :desc) }
  }.freeze

  class << self
    # Articles `viewer` is allowed to see. `base` is the candidate set the
    # visibility rule is applied to — the web feed widens it to every
    # non-draft with the card preload chain, the JSON API narrows it to
    # published or owned articles, the reference picker to accessible ones.
    def for(viewer, base: Article.only_published, hide_blocked_authors: true)
      relation = base.extending(Query)
      relation = relation.excluding_blocked_authors(viewer) if hide_blocked_authors

      relation
    end

    # Authors `viewer` is allowed to see — the author-side half of the same
    # rule. `HomeController#active_authors` samples this list.
    def authors(viewer, base: User.active)
      return base if viewer.blank?

      base
        .where.not(id: blocked_by(viewer))
        .where.not(id: blocking(viewer))
        .excluding(viewer)
    end

    # Strip and cap a single free-text param.
    def cap(text)
      text.to_s.strip.first(QUERY_LENGTH_LIMIT)
    end

    # Cap a comma-separated query param into one capped term per element.
    # `API::ArticlesController#index` contract: `?query=a,b` matches either.
    def cap_each(text)
      text
        .to_s.first(QUERY_LENGTH_LIMIT)
        .split(",")
        .map { |term| term.strip.first(QUERY_LENGTH_LIMIT) }
        .reject(&:blank?)
    end

    # Users `viewer` has blocked.
    def blocked_by(viewer)
      Action
        .where(user_id: viewer.id, user_type: "User", action_type: "block", target_type: "User")
        .select(:target_id)
    end

    # Users who have blocked `viewer`. `viewer` is filtered out of their own
    # blocker list so the two-directional rule can never hide the viewer's own
    # articles from them.
    def blocking(viewer)
      Action
        .where(target_id: viewer.id, target_type: "User", user_type: "User", action_type: "block")
        .where.not(user_id: viewer.id)
        .select(:user_id)
    end
  end

  # Chainable builders mixed into the relation returned by `.for` via
  # `ActiveRecord::Relation#extending`. Keeping them here — rather than as
  # scopes on `Article` — is what lets a non-visibility caller still compose
  # the same vocabulary without widening the model's public surface.
  module Query
    # OR across the searchable columns. `terms` is a single string (web feed)
    # or a list of comma-split terms (JSON API).
    def searching(terms, fields: SEARCH_FIELDS)
      patterns = Array(terms).map { |term| term.to_s.strip.first(QUERY_LENGTH_LIMIT) }.reject(&:blank?)
      return self if patterns.empty?

      predicates = fields.to_h { |field| [ SEARCH_PREDICATES.fetch(field), patterns ] }
      ransack(predicates.merge(m: "or")).result(distinct: true)
    end

    def tagged(name)
      term = name.to_s.strip.first(QUERY_LENGTH_LIMIT)
      return self if term.blank?

      ransack({ tags_name_i_cont_all: term }).result(distinct: true)
    end

    def in_range(range)
      case range
      when "week" then where(published_at: 1.week.ago...)
      when "month" then where(published_at: 1.month.ago...)
      when "year" then where(published_at: 1.year.ago...)
      else self
      end
    end

    def ordered_by(key)
      order = ORDERS.fetch(key.to_sym) { raise ArgumentError, "unknown article order: #{key.inspect}" }

      instance_exec(&order)
    end

    # Articles by authors `viewer` subscribed to, or inside a collection the
    # viewer bought — the definition of the web feed's `subscribed` filter.
    # Both halves stay as SQL subqueries so no ID list is materialised in Ruby.
    def subscribed_to(viewer)
      return none if viewer.blank?

      subscribed_author_ids =
        Action
          .where(user_id: viewer.id, action_type: "subscribe", target_type: "User")
          .select(:target_id)
      owned_collection_uuids =
        Collection
          .joins(:buy_orders)
          .where(buy_orders: { buyer_id: viewer.id })
          .select(:uuid)

      where(author_id: subscribed_author_ids)
        .or(where(collection_id: owned_collection_uuids))
    end

    # Articles the viewer paid for.
    def bought_by(viewer)
      return none if viewer.blank?

      where(id: viewer.bought_articles.select(:id))
    end

    def excluding_blocked_authors(viewer)
      return self if viewer.blank?

      where.not(author_id: ArticleVisibility.blocked_by(viewer))
           .where.not(author_id: ArticleVisibility.blocking(viewer))
    end
  end
end
