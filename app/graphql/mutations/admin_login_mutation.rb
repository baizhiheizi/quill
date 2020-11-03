# frozen_string_literal: true

module Mutations
  class AdminLoginMutation < Mutations::BaseMutation
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
