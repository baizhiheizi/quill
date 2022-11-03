# frozen_string_literal: true

module Articles::Arweavable
  extend ActiveSupport::Concern

  def upload_to_arweave_as_author!
    arweave_transactions.create!(
      owner: author,
      article_snapshot: snapshots.order(created_at: :desc).first
    )
  end

  def arweave_tx
    arweave_transactions.where(owner: nil).order(created_at: :desc).first
  end

  def arweave_tx_of(user)
    owner ||= free? ? author : user

    return unless owner.is_a? User

    arweave_transactions.where(owner: owner).order(created_at: :desc).first
  end
end
