# frozen_string_literal: true

module AdvisoryLockable
  extend ActiveSupport::Concern

  def with_advisory_lock(key, &block)
    lock_id = AdvisoryLockable.lock_id_for(key)

    ActiveRecord::Base.connection_pool.with_connection do |conn|
      acquired = conn.select_value("SELECT pg_try_advisory_lock(#{lock_id})")

      if acquired
        begin
          block.call
        ensure
          conn.execute("SELECT pg_advisory_unlock(#{lock_id})")
        end
      else
        Rails.logger.warn "Advisory lock '#{key}' not acquired — operation skipped"
      end
    end
  end

  def self.lock_id_for(key)
    Digest::SHA256.hexdigest(key.to_s).to_i(16) % (2**63) - 2**63
  end
end
