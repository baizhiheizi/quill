# frozen_string_literal: true

module RichTextContent
  extend ActiveSupport::Concern

  included do
    has_rich_text :content

    before_save :track_content_change
    validate :content_plain_text_length, if: -> { self.class.content_length_limit.present? }

    ransacker :content do |parent|
      table = parent.table
      Arel.sql(
        <<~SQL.squish
          (SELECT action_text_rich_texts.body
           FROM action_text_rich_texts
           WHERE action_text_rich_texts.record_type = '#{name}'
             AND action_text_rich_texts.record_id = #{table.name}.id
             AND action_text_rich_texts.name = 'content'
           LIMIT 1)
        SQL
      )
    end
  end

  class_methods do
    def content_length_limit
      nil
    end
  end

  def content_as_html
    RichTextRenderService.call(content, type: :full)
  end

  def content_body
    content.body.to_html
  end

  def plain_text
    @plain_text ||= content.to_plain_text
  end

  private

  def track_content_change
    @content_changed = content.changed?
  end

  def content_changed_since_save?
    @content_changed == true
  end

  def content_plain_text_length
    return if content.blank?

    limit = self.class.content_length_limit
    return if limit.blank?

    if content.to_plain_text.length > limit
      errors.add(:content, :too_long, count: limit)
    end
  end
end
