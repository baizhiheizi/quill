# frozen_string_literal: true

module Resolvers
  class AdminArticleSnapshotConnectionResolver < AdminBaseResolver
    argument :article_uuid, String, required: false
    argument :state, String, required: false
    argument :query, String, required: false
    argument :after, String, required: false

    type Types::ArticleSnapshotType.connection_type, null: false

    def resolve(**params)
      snapshots =
        if params[:article_uuid].present?
          Article.find_by(uuid: params[:article_uuid]).snapshots
        else
          ArticleSnapshot.all
        end

      q = params[:query].to_s.strip
      q_ransack = { author_mixin_id: q, author_name_cont: q, article_content_cont: q, article_title_cont: q, file_hash_eq: q, tx_id_eq: q }
      snapshots = snapshots.ransack(q_ransack.merge(m: 'or')).result.order(created_at: :desc)

      case params[:state]
      when 'drafted'
        snapshots.drafted
      when 'signing'
        snapshots.signing
      when 'signed'
        snapshots.signed
      else
        snapshots
      end
    end
  end
end
