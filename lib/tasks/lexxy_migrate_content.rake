# frozen_string_literal: true

namespace :lexxy do
  desc "Migrate legacy Markdown content to Action Text HTML for articles and comments"
  task migrate_content: :environment do
    migrate_records(Article, :legacy_markdown_content)
    migrate_records(Comment, :legacy_markdown_content)
  end

  def self.migrate_records(model, column)
    scope = model.where.not(column => [ nil, "" ])
    total = scope.count
    migrated = 0
    skipped = 0
    failed = 0

    puts "Migrating #{total} #{model.name} records..."

    scope.find_each do |record|
      markdown = record.public_send(column)
      if record.content.body.present?
        skipped += 1
        next
      end

      record.content = convert_markdown(markdown)
      if record.save
        migrated += 1
      else
        failed += 1
        puts "Failed #{model.name}##{record.id}: #{record.errors.full_messages.join(', ')}"
      end
    rescue StandardError => e
      failed += 1
      puts "Failed #{model.name}##{record.id}: #{e.message}"
    end

    puts "#{model.name}: migrated=#{migrated} skipped=#{skipped} failed=#{failed}"
  end

  def self.convert_markdown(markdown)
    html = Kramdown::Document.new(markdown.to_s, input: "GFM").to_html
    resolve_blob_urls(html)
  end

  def self.resolve_blob_urls(html)
    html.gsub(%r{(blob://[^"\s\)]+)}) do |url|
      key = url.delete_prefix("blob://").split("/").first
      blob = ActiveStorage::Blob.find_by(key:)
      blob&.url || url
    end
  end
end
