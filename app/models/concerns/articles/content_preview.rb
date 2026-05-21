# frozen_string_literal: true

module Articles::ContentPreview
  extend ActiveSupport::Concern

  def words_count
    @words_count ||= plain_text.scan(/[a-zA-Z]+|\S/).size
  end

  def partial_content
    return if words_count < 300
    return if free_content_ratio.zero?

    plain_text.truncate((words_count * free_content_ratio).to_i)
  end

  def partial_content_as_html
    return "" if free_content_ratio.zero?

    @partial_content_as_html ||= extract_html(content_as_html, (words_count * free_content_ratio).to_i)
  end

  def extract_html(text, length)
    count = 0
    html = ""

    Nokogiri::HTML.fragment(text).children.each do |child|
      if (length - count - child.text.size).positive?
        count += child.text.size
        html += child.to_s
      elsif child.to_s.empty?
        html += child.to_s
      elsif (length - count).positive?
        case child
        when Nokogiri::XML::NodeSet
          child.inner_html = extract_html(child.to_s, length - count)
        when Nokogiri::XML::Text
          child.content = child.text.truncate(length - count)
        end

        count = length
        html += child.to_s
      end
    end

    html
  end

  def default_intro
    plain_text.truncate(140)
  end

  def upvote_ratio
    return if upvotes_count.zero? && downvotes_count.zero?

    "#{format('%.0f', upvotes_count.to_f * 100 / (upvotes_count + downvotes_count))}%"
  end
end
