# frozen_string_literal: true

class Collectibles::MintJob < ApplicationJob
  def perform(id)
    Collectible.find_by(id: id)&.do_mint!
  end
end
