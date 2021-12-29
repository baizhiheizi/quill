# frozen_string_literal: true

class TagsController < ApplicationController
  def index
    q = { name_i_cont: params[:query].to_s.strip }
    @pagy, @tags = pagy Tag.ransack(q.merge(m: 'or')).result

    respond_to do |format|
      format.html
      format.json do
        render json: @tags.pluck(:name)
      end
    end
  end
end
