# frozen_string_literal: true

class MVM::FaucetsController < MVM::BaseController
  def create
    current_user.claim_faucet!
  end
end
