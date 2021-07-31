# frozen_string_literal: true

module Resolvers
  class TagResolver < BaseResolver
    argument :id, ID, required: false
    argument :name, String, required: false

    type Types::TagType, null: true

    def resolve(**params)
      if params[:id].present?
        Tag.find_by id: params[:id]
      else
        Tag.find_by(name: params[:name]) ||
          Tag.ransack(name_i_cont: params[:name].to_s.strip).result.first
      end
    end
  end
end
