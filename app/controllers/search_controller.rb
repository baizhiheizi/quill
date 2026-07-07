# frozen_string_literal: true

class SearchController < ApplicationController
  layout "public", only: :index

  # Cap query length so a multi-kB `params[:query]` can't inflate the ILIKE
  # pattern into an expensive seq-scan. Paired with the pg_trgm GIN indexes
  # (see db/migrate/*_add_pg_trgm_indexes_for_search.rb) this keeps `i_cont`
  # predicates cheap.
  QUERY_LENGTH_LIMIT = 64

  def index
    @query = params[:query].to_s.strip.first(QUERY_LENGTH_LIMIT)

    @users =
      User
        .all
        .ransack(
          {
            name_i_cont_any: @query,
            mixin_id: @query
          }.merge(m: "or")
        ).result
        .limit(10)

    @tags =
      Tag
        .all
        .ransack(
          {
            name_i_cont_any: @query
          }.merge(m: "or")
        ).result
        .limit(10)
  end
end
