# frozen_string_literal: true

class CreateTagService
  def self.call(article, tag_names, with_remove: true)
    new(article, tag_names, with_remove:).call
  end

  def initialize(article, tag_names, with_remove: true)
    @article = article
    @tag_names = tag_names
    @with_remove = with_remove
  end

  def call
    return if tag_names.blank?

    tag_names.compact_blank!

    existing = Tag.where(name: tag_names.map(&:strip)).index_by(&:name)
    new_tags = tag_names.map do |name|
      existing[name.strip] || Tag.find_or_create_by(name: name.strip)
    end
    old_tags = article.tags.to_a
    add_tags = (new_tags - old_tags)
    remove_tags = (old_tags - new_tags)

    add_tags.each { |x| article.taggings.create(tag: x) }
    article.taggings.where(tag: remove_tags).destroy_all if with_remove
    article.tags.reload
  end

  private

  attr_reader :article, :tag_names, :with_remove
end
