# frozen_string_literal: true

module Articles::Arweavable
  extend ActiveSupport::Concern

  def upload_to_arweave!
    arweave_transactions.create_with(
      article_snapshot: snapshots.order(created_at: :desc).first
    ).find_or_create_by!(
      digest: SHA3::Digest::SHA256.hexdigest(content)
    )
  end

  def upload_to_arweave_as_author!
    arweave_transactions.create_with(
      owner: author,
      article_snapshot: snapshots.order(created_at: :desc).first
    ).find_or_create_by!(
      digest: SHA3::Digest::SHA256.hexdigest(content)
    )
  end

  def default_arweave_tx
    @default_arweave_tx ||= arweave_transactions.where(owner: nil).order(created_at: :desc).first
  end

  def arweave_tx_of(user)
    return default_arweave_tx if user.blank? || !user.is_a?(User)

    arweave_transactions.where(owner: user).order(created_at: :desc).first || default_arweave_tx
  end
end
