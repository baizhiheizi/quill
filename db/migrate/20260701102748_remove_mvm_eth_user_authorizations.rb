class RemoveMvmEthUserAuthorizations < ActiveRecord::Migration[8.1]
  # MVM (Mixin Virtual Machine) and Fennec (Pando browser-extension wallet) are
  # both deprecated; their auth paths have been removed. The
  # `user_authorizations.provider` enum keeps its numeric values
  # (mixin: 0, fennec: 1, mvm_eth: 2, twitter: 3) so historical rows still load;
  # this migration purges the orphaned fennec (1) and mvm_eth (2) authorizations
  # and any users whose *only* authorization was one of them (they can no
  # longer sign in).
  #
  # Users that also have a mixin/twitter authorization are kept — only their
  # fennec/mvm_eth authorization rows are removed.
  DEPRECATED_PROVIDERS = [ 1, 2 ].freeze # fennec, mvm_eth

  def up
    # Users whose only authorization is a deprecated provider. Materialized up
    # front: deleting the deprecated rows below would otherwise make a
    # re-evaluated subquery see none of them, silently turning the later user
    # cleanup into a no-op.
    orphan_user_ids = select_values(<<~SQL.squish)
      SELECT user_id FROM user_authorizations
      WHERE provider IN (#{DEPRECATED_PROVIDERS.join(',')}) AND user_id IS NOT NULL
      AND user_id NOT IN (
        SELECT user_id FROM user_authorizations
        WHERE provider NOT IN (#{DEPRECATED_PROVIDERS.join(',')}) AND user_id IS NOT NULL
      )
    SQL

    return if orphan_user_ids.empty?

    # Clear dependent rows that use restrict_with_exception dependencies.
    execute "DELETE FROM sessions WHERE user_id IN (#{orphan_user_ids.join(',')})"
    execute <<~SQL.squish
      DELETE FROM noticed_notifications
      WHERE recipient_type = 'User'
      AND recipient_id IN (#{orphan_user_ids.join(',')})
    SQL

    # Drop all fennec/mvm_eth authorizations.
    execute "DELETE FROM user_authorizations WHERE provider IN (#{DEPRECATED_PROVIDERS.join(',')})"

    # Drop users left without any authorization.
    execute <<~SQL.squish
      DELETE FROM users
      WHERE id IN (#{orphan_user_ids.join(',')})
      AND id NOT IN (SELECT user_id FROM user_authorizations WHERE user_id IS NOT NULL)
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
