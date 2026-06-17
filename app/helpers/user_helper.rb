# frozen_string_literal: true

module UserHelper
  def avatar_initials(name)
    return "?" if name.blank?

    tokens = name.strip.split(/\s+/).reject(&:blank?)
    return "?" if tokens.empty?

    tokens.first(2).map { |token| token.each_grapheme_cluster.first }.join.upcase
  end
end
