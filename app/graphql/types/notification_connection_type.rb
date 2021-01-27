# frozen_string_literal: true

module Types
  class NotificationConnectionType < Types::BaseConnection
    edge_type(Types::NotificationType.edge_type)
  end
end
