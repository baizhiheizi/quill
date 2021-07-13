# frozen_string_literal: true

class Types::MixinNetworkUserOwnerUnion < Types::BaseUnion
  description "Mixin network user' owner"
  possible_types Types::ArticleType, Types::UserType

  def self.resolve_type(object, _context)
    Types::ArticleType if object.is_a?(Article)
    Types::UserType if object.is_a?(User)
  end
end
