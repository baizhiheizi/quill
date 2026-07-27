# frozen_string_literal: true

# Make Solid Cache tolerant of a corrupted cache database.
#
# Why this exists:
#   Solid Cache's upstream Failsafe only rescues a small, hardcoded list of
#   "transient" ActiveRecord errors (timeouts, deadlocks, lost connections).
#   It does NOT rescue ActiveRecord::StatementInvalid, which is the wrapper
#   ActiveRecord puts around the native SQLite3::CorruptException raised when
#   the cache database file is malformed.
#
#   When the cache database gets corrupted (typically because the container
#   is SIGKILL'd mid-write during a deploy or auto-scale), every read/write/
#   delete call therefore raises an unhandled error. The error bubbles up
#   through ActionView's `cache` helper (see app/views/articles/_widgets.html.erb)
#   and 500s the request, even though a cache miss would be a perfectly fine
#   fallback.
#
# What this does:
#   - Prepends a module on SolidCache::Store::Failsafe that expands the rescue
#     list to include ActiveRecord::StatementInvalid.
#   - For rescued errors we report to Rails.error (so the corruption is
#     observable) and let SolidCache's existing error_handler run.
#   - Returns the failsafe_returning value (nil / false / 0 / {}) so callers
#     see the same fallback they would for any other transient error: a
#     cache miss on read, a no-op on write, etc.
module SolidCacheFailsafeStatementInvalidExt
  def failsafe(method, returning: nil)
    yield
  rescue *extended_rescue_list, ActiveRecord::StatementInvalid => error
    ActiveSupport.error_reporter&.report(error, handled: true, severity: :warning,
                                                    context: { cache_method: method, cache_store: "SolidCache" })
    error_handler&.call(method: method, exception: error, returning: returning)
    returning
  end

  private
    def extended_rescue_list
      SolidCache::Store::Failsafe::TRANSIENT_ACTIVE_RECORD_ERRORS
    end
end

SolidCache::Store::Failsafe.prepend(SolidCacheFailsafeStatementInvalidExt)
