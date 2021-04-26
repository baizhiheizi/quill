# frozen_string_literal: true

xml.instruct! :xml, version: '1.0'
xml.rss version: '2.0' do
  xml.channel do
    xml.title 'PRSDigg'
    xml.description 'PRSDigg Articles'
    xml.link root_url

    @articles.each do |article|
      xml.item do
        xml.title article.title
        xml.description article.intro
        xml.pubDate article.published_at.rfc822
        xml.link article_url(article)
        xml.guid article_url(article)
      end
    end
  end
end
