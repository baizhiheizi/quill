# frozen_string_literal: true

# == Schema Information
#
# Table name: article_snapshots
#
#  id           :bigint           not null, primary key
#  article_uuid :uuid
#  file_content :text
#  file_hash    :string
#  raw          :json
#  requested_at :datetime
#  signed_at    :datetime
#  state        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  tx_id        :string
#
# Indexes
#
#  index_article_snapshots_on_article_uuid  (article_uuid)
#  index_article_snapshots_on_tx_id         (tx_id) UNIQUE
#

class ArticleSnapshot < ApplicationRecord
  include AASM

  has_one_attached :file

  belongs_to :article, primary_key: :uuid, foreign_key: :article_uuid, inverse_of: :snapshots

  before_validation :set_defaults, on: :create

  delegate :author, to: :article

  aasm column: :state do
    state :drafted, initial: true
    state :signing
    state :signed

    event :request_sign, after_commit: :touch_requested_at do
      transitions from: :drafted, to: :signing
    end

    event :sign do
      transitions from: :signing, to: :signed
    end
  end

  def touch_requested_at
    update requested_at: Time.current
  end

  def fresh?
    article.snapshots.where('created_at > ?', created_at).blank?
  end

  private

  def set_defaults
    return unless new_record?

    assign_attributes(
      raw: article.as_json,
      file_content: generate_file_content,
      file_hash: SHA3::Digest::SHA256.hexdigest(generate_file_content)
    )
  end

  def generate_file_content
    format(
      file_tpl,
      title: article.title,
      author: author.name,
      author_mixin_uuid: author.mixin_uuid,
      author_avatar: author.avatar,
      bio: author.bio,
      intro: article.intro,
      published_at: article.published_at,
      updated_at: article.updated_at,
      content: article.content
    )
  end

  def file_tpl
    <<~MD
      ---
      title: %<title>s
      author: %<author>s
      author_avatar: %<author_avatar>s
      author_mixin_uuid: %<author_mixin_uuid>s
      bio: %<bio>s
      intro: %<intro>s
      published: %<published_at>s
      updated: %<updated_at>s
      ---

      %<content>s
    MD
  end
end
