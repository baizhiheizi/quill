# frozen_string_literal: true

module Types
  class AnnouncementConnectionType < Types::BaseConnection
    edge_type(Types::AnnouncementType.edge_type)
  end
end
