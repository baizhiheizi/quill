class MigrateFennecProvider < ActiveRecord::Migration[7.0]
  def change
    User
      .where(mixin_id: 0, authorization: { provider: :mixin })
      .or(
        User.where(authorization: { provider: :mixin })
        .where('mixin_id ~* ?', '\A(7000)\d{6}\Z')
      ).each do |user|
        user.authorization.update provider: :fennec
      end
  end
end
