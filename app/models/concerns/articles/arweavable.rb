# frozen_string_literal: true

module Articles::Arweavable
  extend ActiveSupport::Concern

  def upload_to_arweave_async
    ArticleUploadToArweaveWorker.perform_async id
  end

  def upload_to_arweave!
    return unless published?

    arweave_transactions.create_with(
      article_snapshot: snapshots.order(created_at: :desc).first
    ).find_or_create_by!(
      owner: nil,
      digest: digest
    )
  end

  def upload_to_arweave_as_author!
    return unless published?

    arweave_transactions.create_with(
      owner: author,
      article_snapshot: snapshots.order(created_at: :desc).first
    ).find_or_create_by!(
      owner: author,
      digest: digest
    )
  end

  def default_arweave_tx
    @default_arweave_tx ||= arweave_transactions.accepted.where(owner: nil).order(created_at: :desc).first
  end

  def arweave_tx_of(user)
    return default_arweave_tx if user.blank? || !user.is_a?(User)

    arweave_transactions.accepted.where(owner: user).order(created_at: :desc).first || default_arweave_tx
  end

  def digest
    @digest ||= SHA3::Digest::SHA256.hexdigest(content)
  end
end
