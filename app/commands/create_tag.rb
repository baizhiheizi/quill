# frozen_string_literal: true

class CreateTag
  prepend SimpleCommand
  include ActiveModel::Validations

  attr_reader :article, :tag_names, :with_remove

  def initialize(article, tag_names, with_remove: true)
    @article = article
    @tag_names = tag_names
    @with_remove = with_remove
  end

  def call
    return if tag_names.blank?

    new_tags = tag_names.map { |x| Tag.find_or_create_by(name: x.strip) }
    old_tags = article.tags.to_a
    add_tags = (new_tags - old_tags)
    remove_tags = (old_tags - new_tags)
    add_tags.each { |x| article.taggings.create(tag: x) }
    article.taggings.where(tag: remove_tags).destroy_all if with_remove
    article.tags.reload
  end
end
