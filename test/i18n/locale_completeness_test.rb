# frozen_string_literal: true

require "test_helper"
require "yaml"

# `en` is the default locale, so a key only `en` defines is a gap for every
# ja/zh-CN reader, and a typo (`reader_tevenue_total`) silently discards a
# finished translation. These tests pin every `en` leaf key to exist in `ja`
# and `zh-CN` for the locale families that ship in all three languages.
class LocaleCompletenessTest < ActiveSupport::TestCase
  LOCALES = %w[ja zh-CN].freeze

  # Families that ship an `en` file but no `ja`/`zh-CN` file. `admin` has no
  # ja/zh-CN translations yet, so it is excluded on purpose. Any family added
  # here must ship `en` only; removing an entry without adding the
  # translations fails the test below rather than silently skipping the
  # family.
  EXCLUDED_FAMILIES = %w[admin].freeze

  # Derived from disk so a newly added trilingual family is guarded
  # automatically, instead of silently returning to an unguarded state.
  FAMILIES = Dir.children(Rails.root.join("config/locales"))
                .select { |file| file.end_with?(".en.yml") }
                .map { |file| file.delete_suffix(".en.yml") }
                .sort - EXCLUDED_FAMILIES
                .freeze

  FAMILIES.each do |family|
    LOCALES.each do |locale|
      test "#{family}.#{locale} defines every en key" do
        locale_file = Rails.root.join("config/locales/#{family}.#{locale}.yml")
        assert File.exist?(locale_file),
               "config/locales/#{family}.#{locale}.yml is missing: the family ships " \
               "en but not #{locale}. Add the translation file, or list the family in " \
               "EXCLUDED_FAMILIES if it deliberately ships en only."

        en_keys = leaf_keys(family, "en")
        other_keys = leaf_keys(family, locale)

        missing = en_keys - other_keys
        assert_empty missing,
                     "#{family}.#{locale} is missing keys that en defines: #{missing.join(', ')}"
      end
    end
  end

  private

  def leaf_keys(family, locale)
    data = YAML.load_file(Rails.root.join("config/locales/#{family}.#{locale}.yml"))
    walk(data.fetch(data.keys.first))
  end

  def walk(hash, prefix = "")
    hash.flat_map do |key, value|
      full_key = "#{prefix}#{key}"
      value.is_a?(Hash) ? walk(value, "#{full_key}.") : [ full_key ]
    end
  end
end
