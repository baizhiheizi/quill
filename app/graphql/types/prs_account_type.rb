# frozen_string_literal: true

module Types
  class PrsAccountType < Types::BaseObject
    field :id, ID, null: false
    field :account, String, null: true
    field :status, String, null: false
    field :public_key, String, null: false

    field :user, Types::UserType, null: false

    def user
      BatchLoader::GraphQL.for(object.user_id).batch do |user_ids, loader|
        User.where(id: user_ids).each { |user| loader.call(user.id, user) }
      end
    end
  end
end
