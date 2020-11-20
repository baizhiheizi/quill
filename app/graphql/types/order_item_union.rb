# frozen_string_literal: true

class Types::OrderItemUnion < Types::BaseUnion
  description "order' item"
  possible_types Types::ArticleType

  def self.resolve_type(object, _context)
    Types::ArticleType if object.is_a?(Article)
  end
end
