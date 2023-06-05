# frozen_string_literal: true

class Orders::DistributeJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: true, lock: :while_executing, on_conflict: :reject, lock_args_method: :lock_args

  def self.lock_args(args)
    args
  end

  def perform(trace_id)
    order = Order.find_by trace_id: trace_id
    return if order.blank?

    order.distribute!
  end
end
