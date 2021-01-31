class CreateNotificationSettings < ActiveRecord::Migration[6.1]
  def change
    create_table :notification_settings do |t|
      t.belongs_to :user
      t.jsonb :webhook, default: '{}'
      t.jsonb :article_published, default: '{}'
      t.jsonb :article_bought, default: '{}'
      t.jsonb :article_rewarded, default: '{}'
      t.jsonb :comment_created, default: '{}'
      t.jsonb :tagging_created, default: '{}'
      t.jsonb :transfer_processed, default: '{}'

      t.timestamps
    end

    User.find_each do |user|
      user.create_notification_setting! if user.notification_setting.blank?
    end
  end
end
