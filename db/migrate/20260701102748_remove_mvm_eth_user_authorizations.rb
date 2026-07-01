class RemoveMvmEthUserAuthorizations < ActiveRecord::Migration[8.1]
  # MVM (Mixin Virtual Machine) is shut down and the mvm_eth auth path has been
  # removed. The `user_authorizations.provider` enum keeps its numeric values
  # (mixin: 0, fennec: 1, mvm_eth: 2, twitter: 3) so historical rows still load;
  # this migration purges the orphaned mvm_eth authorizations and any users whose
  # *only* authorization was mvm_eth (they can no longer sign in).
  #
  # Users that also have a mixin/fennec/twitter authorization are kept — only
  # their mvm_eth authorization row is removed.
  def up
    # Users whose only authorization is mvm_eth.
    orphan_user_ids_sql = <<~SQL.squish
      SELECT user_id FROM user_authorizations
      WHERE provider = 2 AND user_id IS NOT NULL
      AND user_id NOT IN (SELECT user_id FROM user_authorizations WHERE provider != 2)
    SQL

    # Clear dependent rows that use restrict_with_exception dependencies.
    execute "DELETE FROM sessions WHERE user_id IN (#{orphan_user_ids_sql})"
    execute <<~SQL.squish
      DELETE FROM noticed_notifications
      WHERE recipient_type = 'User'
      AND recipient_id IN (#{orphan_user_ids_sql})
    SQL

    # Drop all mvm_eth authorizations.
    execute "DELETE FROM user_authorizations WHERE provider = 2"

    # Drop users left without any authorization.
    execute <<~SQL.squish
      DELETE FROM users
      WHERE id IN (#{orphan_user_ids_sql})
      AND id NOT IN (SELECT user_id FROM user_authorizations WHERE user_id IS NOT NULL)
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
