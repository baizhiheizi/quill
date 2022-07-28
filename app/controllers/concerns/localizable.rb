# frozen_string_literal: true

module Localizable
  extend ActiveSupport::Concern

  private

  def browser_locale
    header = request.env['HTTP_ACCEPT_LANGUAGE']
    return if header.nil?

    locales = header.gsub(/\s+/, '').split(',').map do |language_tag|
      locale, quality = language_tag.split(/;q=/i)
      quality = quality ? quality.to_f : 1.0
      [locale, quality]
    end

    locales = locales.reject do |(locale, quality)|
      locale == '*' || quality.zero?
    end

    locales = locales.sort_by do |(_, quality)|
      quality
    end

    locales = locales.map(&:first)

    return if locales.empty?

    if I18n.enforce_available_locales
      locale = locales.reverse.find { |l| I18n.available_locales.any? { |al| match?(al, l) } }
      I18n.available_locales.find { |al| match?(al, locale) } if locale
    else
      locales.last
    end
  end

  def match?(sym1, sym2)
    sym1.to_s.casecmp(sym2.to_s).zero?
  end
end
