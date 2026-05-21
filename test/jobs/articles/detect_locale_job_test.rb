# frozen_string_literal: true

require "test_helper"

class Articles::DetectLocaleJobTest < JobTestCase
  test "perform no-ops for missing article" do
    assert_nothing_raised { Articles::DetectLocaleJob.perform_now(SecureRandom.uuid) }
  end

  test "perform calls detect_locale on article" do
    article = articles(:published_paid)
    called = false
    article.define_singleton_method(:detect_locale) { called = true }

    stub_class_method(Article, :find_by, ->(**kwargs) { kwargs[:uuid] == article.uuid ? article : nil }) do
      Articles::DetectLocaleJob.perform_now(article.uuid)
    end

    assert called
  end
end
