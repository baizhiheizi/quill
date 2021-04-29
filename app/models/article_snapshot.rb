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
#  signature    :string
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
  has_one_attached :file

  belongs_to :article, primary_key: :uuid, foreign_key: :article_uuid, inverse_of: :snapshots

  has_one :prs_transaction, class_name: 'ArticlePrsTransaction', primary_key: :tx_id,\
                            foreign_key: :tx_id, inverse_of: :article_snapshot,\
                            dependent: :restrict_with_error

  before_validation :set_defaults, on: :create
  after_commit :sign_on_chain_async, on: :create

  delegate :author, to: :article

  def sign_on_chain!
    return if prs_transaction.present?

    r =
      Prs.api.sign(
        {
          type: 'PIP:2001',
          meta: {
            uris: [
              file.url,
              format('%<host>s/api/files/%<file_hash>s', host: Rails.application.credentials[:host], file_hash: file_hash)
            ],
            mime: 'text/markdown;charset=UTF-8',
            encryption: 'aes-256-cbc',
            payment_url: "mixin://transfer/#{article.wallet.uuid}"
          },
          data: {
            file_hash: file_hash,
            topic: Rails.application.credentials.dig(:prs, :account),
            updated_tx_id: article.current_prs_transaction&.tx_id
          }
        },
        {
          account: author.prs_account.account,
          private_key: author.prs_account.private_key
        }
      )

    ActiveRecord::Base.transaction do
      block = r['processed']['action_traces'][0]['act']['data']
      update tx_id: block['id']
      author
        .prs_account
        .transactions
        .create_with(raw: block, type: 'ArticlePrsTransaction')
        .find_or_create_by!(transation_id: r['transaction_id'])
    end
  end

  def sign_on_chain_async
    ArticleSnapshotSignOnChainWorker.perform_async id
  end

  def encrypted_file_content
    Prs.api.pip2001_encrypt file_content, article_uuid
  end

  def upload_encrypted_file_content
    file.attach(
      io: StringIO.new(encrypted_file_content),
      filename: "#{file_hash}.md",
      content_type: 'text/markdown;charset=UTF-8'
    )
  end

  def signature_url
    prs_transaction&.block_url
  end

  private

  def set_defaults
    return unless new_record?

    assign_attributes(
      raw: article.as_json,
      file_content: generate_file_content,
      file_hash: Prs.api.hash(generate_file_content)
    )
  end

  def generate_file_content
    format(
      file_tmp,
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

  def file_tmp
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
