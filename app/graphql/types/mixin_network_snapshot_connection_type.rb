# frozen_string_literal: true

module Types
  class MixinNetworkSnapshotConnectionType < Types::BaseConnection
    edge_type(Types::MixinNetworkSnapshotType.edge_type)
  end
end
