# frozen_string_literal: true

module Resolvers
  class AdminMixinNetworkSnapshotConnectionResolver < AdminBaseResolver
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
        else
          MixinNetworkSnapshot.all
        end
      snapshots.order(created_at: :desc)
    end
  end
end
