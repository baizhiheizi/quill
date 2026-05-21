# frozen_string_literal: true

module RichTextContent
  extend ActiveSupport::Concern

  included do
    has_rich_text :content

    before_save :track_content_change
    validate :content_cannot_be_blank, if: :validate_rich_text_content_presence?
    validate :content_plain_text_length, if: -> { self.class.content_length_limit.present? }

    ransacker :content do |parent|
      table = parent.table
      Arel.sql(
        <<~SQL.squish
          COALESCE(
            (SELECT action_text_rich_texts.body
             FROM action_text_rich_texts
             WHERE action_text_rich_texts.record_type = '#{name}'
               AND action_text_rich_texts.record_id = #{table.name}.id
               AND action_text_rich_texts.name = 'content'
             LIMIT 1),
            #{table.name}.legacy_markdown_content
          )
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
    if migrated_content?
      RichTextRenderService.call(content, type: :full)
    elsif legacy_markdown_content.present?
      MarkdownRenderService.call(legacy_markdown_content, type: :full)
    else
      ""
    end
  end

  def content_body
    if migrated_content?
      content.body.to_html
    elsif legacy_markdown_content.present?
      MarkdownRenderService.call(legacy_markdown_content, type: :default)
    else
      ""
    end
  end

  def plain_text
    @plain_text ||=
      if migrated_content?
        content.to_plain_text
      else
        legacy_markdown_content.to_s
      end
  end

  def migrated_content?
    content.body.present?
  end

  def validate_rich_text_content_presence?
    true
  end

  private

  def track_content_change
    @content_changed = content.changed?
  end

  def content_changed_since_save?
    @content_changed == true
  end

  def content_cannot_be_blank
    return if migrated_content? || legacy_markdown_content.present?

    errors.add(:content, :blank)
  end

  def content_plain_text_length
    return if plain_text.blank?

    limit = self.class.content_length_limit
    return if limit.blank?

    if plain_text.length > limit
      errors.add(:content, :too_long, count: limit)
    end
  end
end
