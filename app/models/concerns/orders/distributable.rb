# frozen_string_literal: true

module Orders::Distributable
  extend ActiveSupport::Concern

  def distribute_async
    Orders::DistributeJob.perform_later trace_id
  end

  def distribute!
    Orders::DistributeService.call(self)
  end
end
