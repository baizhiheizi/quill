# frozen_string_literal: true

class Transfers::ProcessJob < ApplicationJob
  queue_as :critical

  limits_concurrency to: 1, key: ->(trace_id) { trace_id }, on_conflict: :discard

  def perform(trace_id)
    Transfer.find_by(trace_id:)&.process_with_rescue!
  end
end
