# frozen_string_literal: true

module Mutations
  class AdminLoginMutation < GraphQL::Schema::RelayClassicMutation
    argument_class Types::BaseArgument
    field_class Types::BaseField
    input_object_class Types::BaseInputObject
    object_class Types::BaseObject

    argument :name, String, required: true
    argument :password, String, required: true

    field :error, String, null: true
    field :success, Boolean, null: true

    def resolve(name:, password:)
      admin = Administrator.find_by(name: name)
      return { error: 'Not Authorized!' } unless admin&.authenticate(password)

      context[:session][:current_admin_id] = admin.id
      {
        success: true
      }
    end
  end
end
