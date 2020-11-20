# frozen_string_literal: true

module Types
  class MixinNetworkUserType < Types::BaseObject
    field :id, ID, null: false
    field :uuid, ID, null: false
    field :name, String, null: false
    field :owner_type, String, null: false
    field :owner_id, Integer, null: false

    field :owner, Types::MixinNetworkUserOwnerUnion, null: true

    def owner
      BatchLoader::GraphQL.for(object.owner_id).batch(owner_type: object.owner_type) do |owner_ids, loader, args|
        model = Object.const_get(args[:owner_type])
        model.where(id: owner_ids).each { |record| loader.call(record.owner_id, record) }
      end
    end
  end
end
