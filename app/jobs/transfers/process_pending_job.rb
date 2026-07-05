# frozen_string_literal: true

class Transfers::ProcessPendingJob < ApplicationJob
  queue_as :critical

  limits_concurrency to: 1, key: ->(*) { "sweep" }

  def perform
    Transfer.process_pending!
  end
end
