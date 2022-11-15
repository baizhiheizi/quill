# frozen_string_literal: true

module Articles::Importable
  extend ActiveSupport::Concern

  def self.import_from_mirror(address)
    author = User.find_by uid: address
    return if author.blank?

    ids = ArweaveBot.graphql.all_mirror_transactions address

    ids.each do |id|
      r = ArweaveBot.api.transaction id
      uuid = Digest::MD5.hexdigest r['digest']

      Article.create_with(
        title: r['content']['title'],
        content: r['content']['body'],
        price: 0
      ).find_or_create_by(uuid: uuid)
    end
  end
end
