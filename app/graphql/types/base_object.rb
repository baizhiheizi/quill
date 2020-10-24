# frozen_string_literal: true

module Types
  class BaseObject < GraphQL::Schema::Object
    include ActionView::Helpers::DateHelper

    field_class Types::BaseField

    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: true
  end
end
