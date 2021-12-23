# frozen_string_literal: true

class SearchController < ApplicationController
  def index
    query = params[:query].to_s.strip

    @users =
      User
      .all
      .ransack(
        {
          name_i_cont_any: query,
          mixin_id: query
        }.merge(m: 'or')
      ).result
      .limit(10)

    @tags =
      Tag
      .all
      .ransack(
        {
          name_i_cont_any: query
        }.merge(m: 'or')
      ).result
      .limit(10)
  end
end
