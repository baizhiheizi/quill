# frozen_string_literal: true

module Mutations
  class SwitchLocaleMutation < Mutations::BaseMutation
    argument :locale, String, required: true

    type Boolean

    def resolve(locale:)
      current_user.update(locale: locale) if locale.to_sym.in? I18n.available_locales
    end
  end
end
