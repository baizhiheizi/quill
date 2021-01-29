# frozen_string_literal: true

module Mutations
  class SwitchLocaleMutation < Mutations::BaseMutation
    argument :locale, String, required: true

    type Boolean

    def resolve(locale:)
      if locale.downcase.include? 'en'
        current_user.update(locale: :en)
      else
        current_user.update(locale: I18n.default_locale)
      end
    end
  end
end
