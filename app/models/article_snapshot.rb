# frozen_string_literal: true

# == Schema Information
#
# Table name: article_snapshots
#
#  id           :bigint           not null, primary key
#  article_uuid :uuid
#  raw          :json
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_article_snapshots_on_article_uuid  (article_uuid)
#

class ArticleSnapshot < ApplicationRecord
  include AASM

  store_accessor :raw, %w[title intro content digest]

  belongs_to :article, primary_key: :uuid, foreign_key: :article_uuid, inverse_of: :snapshots
  has_one :arweave_transaction, dependent: :restrict_with_exception

  before_validation :set_defaults, on: :create

  delegate :author, to: :article

  def fresh?
    article.snapshots.where('created_at > ?', created_at).blank?
  end

  def previous_signed_snapshot
    article.snapshots.signed.where('created_at < ?', created_at).order(created_at: :desc).first
  end

  private

  def set_defaults
    return unless new_record?

    assign_attributes(
      raw: article.as_json.merge(digest: SHA3::Digest::SHA256.hexdigest(article.content))
    )
  end
end
