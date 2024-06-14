# frozen_string_literal: true

class Collectibles::TransferToOwnerJob < ApplicationJob
  def perform(id)
    Collectible.find_by(id:)&.transfer_to_owner
  end
end
