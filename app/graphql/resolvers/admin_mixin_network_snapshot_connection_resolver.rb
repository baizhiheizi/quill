# frozen_string_literal: true

module Resolvers
  class AdminMixinNetworkSnapshotConnectionResolver < AdminBaseResolver
    argument :user_id, String, required: false
    argument :filter, String, required: false
    argument :after, String, required: false

    type Types::MixinNetworkSnapshotConnectionType, null: false

    def resolve(params)
      snapshots =
        case params[:filter]
        when 'input'
          MixinNetworkSnapshot.only_input
        when 'output'
          MixinNetworkSnapshot.only_output
        when 'prsdigg'
          MixinNetworkSnapshot.only_prsdigg
        when '4swap'
          MixinNetworkSnapshot.only_4swap
        else
          MixinNetworkSnapshot.all
        end

      snapshots = snapshots.where(user_id: params[:user_id]) if params[:user_id].present?
      snapshots.order(created_at: :desc)
    end
  end
end
