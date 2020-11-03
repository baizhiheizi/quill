# frozen_string_literal: true

module Mutations
  class AdminBaseMutation < GraphQL::Schema::RelayClassicMutation
    argument_class Types::BaseArgument
    field_class Types::BaseField
    input_object_class Types::BaseInputObject
    object_class Types::BaseObject

    def current_admin
      @current_admin = context[:session][:current_admin]
    end

    def self.authorized?(_object, context)
      super && context[:session][:current_admin].present?
    end
  end
end
