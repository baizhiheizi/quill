class MigrateSubscriberData < ActiveRecord::Migration[6.1]
  def change
    User.find_each do |user|
      user.authoring_subscribe_users.each do |_user|
        user.create_action :subscribe, target: _user
      end
      user.reading_subscribe_users.each do |_user|
        user.create_action :subscribe, target: _user
      end
    end
  end
end
