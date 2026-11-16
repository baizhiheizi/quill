# frozen_string_literal: true

require "test_helper"
require "yaml"

# Rails renders `translation missing` strings wherever a key exists in one
# locale but not another, and `en` is the default locale — so a key that only
# `en` defines is a user-visible gap for every ja/zh-CN reader, and vice versa
# is how a typo (`reader_tevenue_total`) silently discards a finished
# translation. These tests pin every `en` leaf key to exist in `ja` and
# `zh-CN` for the locale families that ship in all three languages.
# `admin.en.yml` is intentionally excluded: the admin UI has no ja/zh-CN
# translations yet.
class LocaleCompletenessTest < ActiveSupport::TestCase
  FAMILIES = %w[views models notifications].freeze
  LOCALES = %w[ja zh-CN].freeze

  FAMILIES.each do |family|
    LOCALES.each do |locale|
      test "#{family}.#{locale} defines every en key" do
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
