Hash: manual
# app/services/article_search_service.rb

`ArticleSearchService` — chainable query builder. `.call(params)` returns a relation.

Stages (all return `self`):
1. `query` — Ransack on title / intro / author name / tag name (OR).
2. `tagging` — Ransack on `tags_name_i_cont_all` when tag present.
3. `filter` — `lately` / `revenue` / `subscribed` / `bought` / default popularity. Uses subqueries (`Action.select(:target_id)`, `bought_articles&.select(:id)`) to avoid Ruby-side ID materialisation.
4. `filter_block_authors` — Excludes blocked/blocker authors via subqueries.
5. `select_in_time_range` — `week` / `month` / `year` filters on `published_at`.
6. `localize` — Filters by locale prefix when no explicit query or tag is given.