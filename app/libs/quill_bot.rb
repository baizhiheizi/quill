# frozen_string_literal: true

module QuillBot
  def self.api
    @api ||= MixinBot::API.new(**Rails.application.credentials[:quill_bot], debug: Rails.env.development?)
  rescue StandardError => e
    Rails.logger.error e
    nil
  end

  def self.generate_app_report
    <<~TEXT
      ## Quill Report #{Time.current.to_date}

      ### Last 24 Hours
      - New Users: #{User.where(created_at: 24.hours.ago...).count}
      - Articles: #{Article.where(published_at: 24.hours.ago...).count}
      - Orders: #{Order.completed.where(created_at: 24.hours.ago...).count}
      - Volume: $#{Order.completed.where(updated_at: 24.hours.ago...).sum(:value_usd).round(4)}

      ### Last 7 days
      - New Users: #{User.where(created_at: 7.days.ago...).count}
      - Articles: #{Article.where(published_at: 7.days.ago...).count}
      - Orders: #{Order.completed.where(created_at: 7.days.ago...).count}
      - Volume: $#{Order.completed.where(updated_at: 7.days.ago...).sum(:value_usd).round(4)}

      ### Last 30 days
      - New Users: #{User.where(created_at: 30.days.ago...).count}
      - Articles: #{Article.where(published_at: 30.days.ago...).count}
      - Orders: #{Order.completed.where(created_at: 30.days.ago...).count}
      - Volume: $#{Order.completed.where(updated_at: 30.days.ago...).sum(:value_usd).round(4)}

      ### Total
      - Users: #{User.count}
      - Articles: #{Article.only_published.count}
      - Orders: #{Order.completed.count}
      - Volume: $#{Order.completed.sum(:value_usd).round(4)}
    TEXT
  end
end
